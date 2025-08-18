# frozen_string_literal: true

class SessionsController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource
  before_action :set_session, only: [:show, :edit, :update, :destroy]
  before_action :set_session_for_cancel, only: [:cancel]

  def index
    @sessions = Session.order(start_at: :desc)
    @sessions = @sessions.terrain(params[:terrain]) if params[:terrain].present?
  end

  def show
    if can?(:manage, Registration) && !@session.coaching_prive?
      registered_ids = @session.registrations.pluck(:user_id)
      base = User.where.not(id: registered_ids)

      # Level filter for trainings with specific levels
      if @session.entrainement? && @session.levels.any?
        base = base.where(level_id: @session.level_ids)
      end

      # Credits filter: always require enough credits
      base = base.joins(:balance).where("balances.amount >= ?", @session.price)

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
      redirect_to sessions_path, notice: "Session créée avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @levels = Level.all
  end

  def update
    @session.assign_attributes(normalized_session_params)
    if @session.save
      sync_participants(@session)
      redirect_to sessions_path, notice: "Session mise à jour avec succès."
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

    redirect_to sessions_path, notice: "Session annulée et remboursée ✅"
  rescue StandardError => e
    redirect_to session_path(@session), alert: "Erreur lors de l'annulation: #{e.message}"
  end

  private

  def set_session
    @session = Session.find(params[:id])
  end

  def set_session_for_cancel
    @session = Session.find(params[:id])
  end

  def session_params
    params.require(:session).permit(
      :title, :description, :start_at, :end_at, 
      :session_type, :max_players, :terrain, :user_id, :price, :cancellation_deadline_at,
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
