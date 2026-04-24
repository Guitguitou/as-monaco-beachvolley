# frozen_string_literal: true

class SessionsController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource
  before_action :set_session, only: [:show, :edit, :update, :destroy]
  before_action :set_session_for_cancel, only: [:cancel]
  before_action :set_session_for_duplicate, only: []

  def index
    @view = params[:view].presence_in(%w[grid calendar]) || "calendar"
    @for_me = ActiveModel::Type::Boolean.new.cast(params[:for_me])
    user_level_ids = current_user.levels.pluck(:id)

    if @view == "calendar"
      anchor = safe_calendar_week_anchor
      week_start = anchor.beginning_of_week(:monday)
      week_end = week_start + 6.days
      @terrain_closures_week = TerrainClosure.intersecting_range(week_start, week_end).order(:terrain, :starts_on)
    end

    # Calendar (existing behavior)
    @sessions = Session.includes(:levels, :user).order(start_at: :desc)
    @sessions = @sessions.terrain(params[:terrain]) if params[:terrain].present?
    @sessions = @sessions.for_user_levels(user_level_ids) if @for_me

    return unless @view == "grid"

    # Grid view data
    @sessions_grid = Session.upcoming.ordered_by_start.includes(:levels, :user)
    @sessions_grid = @sessions_grid.terrain(params[:terrain]) if params[:terrain].present?
    @sessions_grid = @sessions_grid.for_user_levels(user_level_ids) if @for_me

    session_ids = @sessions_grid.pluck(:id)
    @registrations_by_session_id = current_user
      .registrations
      .where(session_id: session_ids)
      .index_by(&:session_id)

    @user_level_ids = user_level_ids
    @user_balance_amount = current_user.balance&.amount.to_i

    @conflict_session_ids = conflict_session_ids_for(session_ids)

    confirmed_counts = Registration
      .where(session_id: session_ids, status: Registration.statuses[:confirmed])
      .group(:session_id)
      .count

    @sessions_registered_grid = @sessions_grid.select { |s| @registrations_by_session_id.key?(s.id) }

    @sessions_eligible_grid = @sessions_grid.reject { |s| @registrations_by_session_id.key?(s.id) }.select do |s|
      eligible_for_grid?(s, confirmed_counts: confirmed_counts)
    end

    # Only show sessions that are either registered/waitlisted or eligible to register
    @sessions_grid = @sessions_registered_grid + @sessions_eligible_grid
  end

  def show
    if can?(:manage, Registration)
      registered_ids = @session.registrations.pluck(:user_id)
      base = User.where.not(id: registered_ids)

      # Level filter for trainings with specific levels: allow users with any matching level
      if @session.entrainement? && @session.levels.any?
        base = base.joins(:user_levels).where(user_levels: { level_id: @session.level_ids }).distinct
      end

      # Credits filter only for non-private sessions
      unless @session.coaching_prive?
        base = base.joins(:balance).where("balances.amount >= ?", @session.price)
      end

      # Avoid schedule conflicts for confirmed adds
      if !@session.full?
        base = base.where.not(
          id: User
                .joins(:sessions_registered)
                .where("sessions.start_at < ? AND sessions.end_at > ?", @session.end_at, @session.start_at)
                .select(:id)
        )
      end

      @candidate_users = base.order(:first_name, :last_name).distinct
    end
  end

  def new
    @session = Session.new
  end

  def create
    @session = Session.new(normalized_session_params)

    if @session.save
      sync_participants(@session)
      redirect_to sessions_path(sessions_index_redirect_params), notice: "Session créée avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @levels = Level.all
  end

  def update
    update_params = normalized_session_params
    # Restrict coach_notes editing to admins or the coach responsible for the session
    if update_params.key?(:coach_notes)
      allowed = current_user.admin? || current_user == @session.user
      update_params.delete(:coach_notes) unless allowed
    end
    @session.assign_attributes(update_params)
    if @session.save
      # Only sync participants if the form included participant_ids
      sync_participants(@session) if params.dig(:session, :participant_ids).present?
      redirect_to sessions_path(sessions_index_redirect_params), notice: "Session mise à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
      flash.now[:alert] = "Erreur lors de la mise à jour de la session: #{@session.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @session.destroy
    redirect_to admin_sessions_path, notice: "Session supprimée avec succès."
  end

  def cancel
    authorize! :cancel, @session

    # Règle 4: Notifier tous les utilisateurs inscrits avant de détruire la session
    session_name = @session.title || @session.session_type.humanize
    session_date = @session.start_at.strftime("%d/%m/%Y")
    registered_users = @session.registrations.confirmed.includes(:user).map(&:user)

    ActiveRecord::Base.transaction do
      # Refund all participants for non-private sessions
      @session.registrations.includes(:user).find_each do |registration|
        amount = registration.required_credits_for(registration.user)
        TransactionService.new(registration.user, @session, amount).refund_transaction if amount.positive?
        registration.destroy!
      end

      # If it's a private coaching, refund the coach for the debit done at creation
      if @session.coaching_prive?
        coach_amount = @session.send(:default_price)
        TransactionService.new(@session.user, @session, coach_amount).refund_transaction if coach_amount.positive?
      end

      # Detach transactions from this session to avoid FK issues, then destroy
      CreditTransaction.where(session_id: @session.id).update_all(session_id: nil)
      @session.destroy!
    end

    # Envoyer les notifications après la destruction (push + email)
    registered_users.each do |user|
      begin
        SendPushNotificationJob.perform_later(
          user.id,
          title: "Session annulée",
          body: "La session #{session_name} du #{session_date} est annulée",
          url: Rails.application.routes.url_helpers.sessions_path
        )
        SessionMailer.session_cancelled(user, session_name: session_name, session_date: session_date).deliver_later
      rescue StandardError => e
        Rails.logger.error "Failed to enqueue notification job for user #{user.id}: #{e.message}"
        # Don't block the process if notification fails
      end
    end

    redirect_to sessions_path(sessions_index_redirect_params), notice: "Session annulée et remboursée ✅"
  rescue StandardError => e
    redirect_to session_path(@session, session_show_query_params), alert: "Erreur lors de l'annulation: #{e.message}"
  end

  # Duplicate moved to admin area

  private

  def safe_calendar_week_anchor
    return Time.zone.today if params[:date].blank?

    Date.parse(params[:date])
  rescue ArgumentError
    Time.zone.today
  end

  def sessions_index_redirect_params
    {
      date: @session.start_at.strftime("%Y-%m-%d"),
      terrain: params[:terrain].presence,
      for_me: ActiveModel::Type::Boolean.new.cast(params[:for_me]) ? "1" : nil,
      view: params[:view].presence_in(%w[grid calendar])
    }.compact
  end

  def session_show_query_params
    {
      view: params[:view].presence_in(%w[grid calendar]),
      date: params[:date].presence,
      for_me: ActiveModel::Type::Boolean.new.cast(params[:for_me]) ? "1" : nil,
      terrain: params[:terrain].presence
    }.compact
  end

  def set_session
    @session = Session.find(params[:id])
  end

  def set_session_for_cancel
    @session = Session.find(params[:id])
  end

  def set_session_for_duplicate
    @session = Session.find(params[:id])
  end

  def conflict_session_ids_for(candidate_session_ids)
    confirmed = current_user.sessions_registered.select(:start_at, :end_at)
    return [] if confirmed.blank?

    # Build an OR of overlap predicates:
    # existing.start < candidate.end AND existing.end > candidate.start
    overlap_sql = []
    overlap_params = []
    confirmed.each do |s|
      overlap_sql << "(start_at < ? AND end_at > ?)"
      overlap_params << s.end_at
      overlap_params << s.start_at
    end

    Session
      .where(id: candidate_session_ids)
      .where(overlap_sql.join(" OR "), *overlap_params)
      .pluck(:id)
  end

  def eligible_for_grid?(session_record, confirmed_counts:)
    # Keep private coachings out of the “inscriptible” list
    return false if session_record.coaching_prive?

    open_ok, = session_record.registration_open_state_for(current_user)
    return false unless open_ok

    # Level constraint for trainings
    if session_record.entrainement? && session_record.levels.any?
      return false unless (session_record.level_ids & @user_level_ids).any?
    end

    # Capacity
    if session_record.max_players.present?
      confirmed = confirmed_counts[session_record.id].to_i
      return false if confirmed >= session_record.max_players
    end

    # Credits constraint (non-private only)
    return false if @user_balance_amount < session_record.price.to_i

    true
  end

  def session_params
    params.require(:session).permit(
      :title, :description, :start_at, :end_at, 
      :session_type, :max_players, :terrain, :user_id, :price, :cancellation_deadline_at, :coach_notes,
      participant_ids: [],
      registrations_attributes: [:id, :user_id, :_destroy],
      level_ids: []
    )
  end

  def normalized_session_params
    sp = session_params.dup
    # Avoid implicit creation of registrations via has_many :participants setter.
    # We handle participant syncing (with debit/refund) explicitly in sync_participants.
    sp.delete(:participant_ids)
    if sp[:end_at].blank? && sp[:start_at].present?
      type = sp[:session_type]
      if ["entrainement", "jeu_libre", "coaching_prive"].include?(type)
        begin
          start_time = Time.zone.parse(sp[:start_at].to_s)
          sp[:end_at] = start_time + 90.minutes if start_time
        rescue ArgumentError
          # leave end_at blank if parse fails
        end
      end
    end
    sp
  end

  def sync_participants(session_record)
    participant_ids = Array(params.dig(:session, :participant_ids)).reject(&:blank?).map(&:to_i)
    current_ids = session_record.participants.pluck(:id)

    ids_to_add = participant_ids - current_ids
    ids_to_remove = current_ids - participant_ids

    errors = []

    ids_to_add.each do |uid|
      registration = Registration.new(user_id: uid, session: session_record, status: :confirmed)
      # Allow privileged add for private coachings
      registration.allow_private_coaching_registration = true if session_record.coaching_prive? && can?(:manage, Registration)
      begin
        ActiveRecord::Base.transaction do
          registration.save!
          amount = registration.required_credits_for(registration.user)
          if amount.positive?
            TransactionService.new(registration.user, session_record, amount).create_transaction
          end
        end
      rescue StandardError => e
        errors << "#{User.find(uid).full_name}: #{registration.errors.full_messages.presence || e.message}"
      end
    end

    ids_to_remove.each do |uid|
      registration = session_record.registrations.find_by(user_id: uid)
      next unless registration
      amount = registration.required_credits_for(registration.user)
      ActiveRecord::Base.transaction do
        registration.destroy!
        if amount.positive?
          TransactionService.new(User.find(uid), session_record, amount).refund_transaction
        end
        # After freeing up a spot, promote the first in waitlist if any
        session_record.promote_from_waitlist!
      end
    end

    flash[:alert] = [flash[:alert], errors.join("; ")].compact.reject(&:blank?).join("; ") if errors.any?
  end

  def ensure_admin!
    redirect_to root_path, alert: "Accès refusé" unless current_user.admin?
  end
end
