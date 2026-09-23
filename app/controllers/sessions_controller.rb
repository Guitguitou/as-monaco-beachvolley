# frozen_string_literal: true

class SessionsController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource
  before_action :set_session, only: [ :show, :edit, :update, :destroy, :calendar, :cancel ]

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

    upcoming = Session.upcoming.ordered_by_start
    upcoming = upcoming.terrain(params[:terrain]) if params[:terrain].present?
    upcoming = upcoming.for_user_levels(user_level_ids) if @for_me
    @grid = Sessions::UpcomingGrid.new(user: current_user, sessions: upcoming)
    # Priorité hebdomadaire : une seule requête pour toute la grille.
    @weekly_ranks_by_session_id = Registrations::UserWeeklyPriorityMap.call(
      user: current_user, sessions: @grid.registered + @grid.eligible
    )
  end

  def show
    @candidate_users = Sessions::CandidateUsersQuery.call(session: @session) if can?(:manage, Registration)
  end

  def calendar
    export = Sessions::IcsExport.new(@session, url: session_url(@session))
    # `inline` : sur iOS Safari, ouvre directement l'écran « Ajouter l'événement »
    # dans Calendar au lieu d'enregistrer le fichier. Le filename reste utile pour
    # les plateformes qui téléchargent quand même (Android, desktop).
    send_data export.call,
              type: "text/calendar; charset=utf-8",
              disposition: "inline",
              filename: export.filename
  end

  def new
    @session = Session.new
  end

  def create
    @session = Session.new(normalized_session_params)

    if @session.save
      @session.sync_level_priorities(params.dig(:session, :level_priorities))
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
      @session.sync_level_priorities(params.dig(:session, :level_priorities))
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

    Sessions::CancelSessionService.call(session: @session)

    redirect_to sessions_path(sessions_index_redirect_params), notice: "Session annulée et remboursée ✅"
  rescue StandardError => e
    redirect_to session_path(@session, session_show_query_params), alert: "Erreur lors de l'annulation: #{e.message}"
  end

  private

  def safe_calendar_week_anchor
    return Time.zone.today if params[:date].blank?

    Date.parse(params[:date])
  rescue ArgumentError
    Time.zone.today
  end

  def sessions_index_redirect_params
    Sessions::ReturnParams.from(params).merge(date: @session.start_at.strftime("%Y-%m-%d"))
  end

  def session_show_query_params
    Sessions::ReturnParams.from(params)
  end

  def set_session
    @session = Session.find(params[:id])
  end

  def session_params
    params.require(:session).permit(
      :title, :description, :start_at, :end_at,
      :session_type, :max_players, :terrain, :user_id, :price, :cancellation_deadline_at, :coach_notes,
      participant_ids: [],
      registrations_attributes: [ :id, :user_id, :_destroy ],
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
      if [ "entrainement", "jeu_libre", "coaching_prive" ].include?(type)
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
    sync = Sessions::ParticipantsSync.new(session: session_record, allow_private_coaching: can?(:manage, Registration))
    append_flash_alert(sync.call(params.dig(:session, :participant_ids)))
  end
end
