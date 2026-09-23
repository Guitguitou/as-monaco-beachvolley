# frozen_string_literal: true

module Admin
  class SessionsController < BaseController
    load_and_authorize_resource
    before_action :set_session, only: [ :show, :edit, :update, :destroy, :duplicate ]

    PER_PAGE = 25

    def index
      result = Sessions::AdminFilterQuery.call(relation: @sessions, params: params)
      @type_counts = result.type_counts
      @total_count = result.total_count
      @current_type = result.current_type

      @total_pages = [ (result.filtered_count.to_f / PER_PAGE).ceil, 1 ].max
      @page = params[:page].to_i.clamp(1, @total_pages)
      @sessions = result.relation.limit(PER_PAGE).offset((@page - 1) * PER_PAGE)
    end

    def show
    end

    def new
      @session = Session.new
    end

    def create
      @session = Session.new(session_params)

      if params.dig(:session, :create_on_all_terrains) == "1"
        create_on_all_terrains
      else
        if @session.save
          @session.sync_level_priorities(params.dig(:session, :level_priorities))
          sync_participants(@session)
          redirect_to admin_session_path(@session), notice: "Session créée avec succès."
        else
          render :new, status: :unprocessable_entity
        end
      end
    end

    def edit
      @levels = Level.all
    end

    def update
      result = Sessions::AdminUpdate.new(
        session: @session, attributes: session_params, level_priorities: params.dig(:session, :level_priorities),
        levels_submitted: params.dig(:session, :level_ids).present?, scope: scope_param
      ).call do
        # Only sync participants if the form included participant_ids to avoid unintended removals
        sync_participants(@session) if params.dig(:session, :participant_ids).present?
      end
      return render(:edit, status: :unprocessable_entity) unless result.saved?

      alert_failures("Certaines sessions n'ont pas pu être mises à jour :", result.failures)
      redirect_to admin_session_path(@session), notice: result.notice
    end

    def destroy
      result = Sessions::SeriesDestroyService.call(session: @session, scope: scope_param)

      notice =
        if scope_param == "following" && result[:destroyed_count] > 1
          "#{result[:destroyed_count]} session(s) supprimée(s) et remboursée(s) ✅"
        else
          "Session supprimée avec succès."
        end
      alert_failures("Certaines suppressions ont échoué :", result[:failures])

      redirect_to admin_sessions_path, notice: notice
    end

    # Duplicate a session weekly for N weeks (admin only)
    def duplicate
      authorize! :manage, Session

      result = DuplicateSessionService.new(@session, params[:weeks]).call

      if result[:success]
        redirect_to admin_sessions_path, notice: "#{result[:created_count]} session(s) créée(s) ✅"
      else
        alert_message = result[:errors].any? ?
          [ "Certaines duplications ont échoué:", *result[:errors] ].join("\n") :
          "Erreur lors de la duplication"
        redirect_to admin_session_path(@session), alert: alert_message
      end
    end

    private

    def set_session
      @session = Session.find(params[:id])
    end

    def alert_failures(heading, failures)
      flash[:alert] = [ heading, *failures ].join("\n") if failures.any?
    end

    # Portée d'une action multi-sessions : "this" (défaut) ou "following".
    def scope_param
      %w[this following].include?(params[:scope]) ? params[:scope] : "this"
    end

    def session_params
      params.require(:session).permit(
        :title, :description, :start_at, :end_at, :session_type, :max_players, :terrain, :user_id, :price,
        :cancellation_deadline_at, :registration_opens_at, :coach_notes,
        level_ids: [], participant_ids: []
      )
    end

    # Authorization handled by CanCanCan

    # Un admin peut inscrire en coaching privé et passer outre la deadline de 17h.
    def sync_participants(session_record)
      sync = Sessions::ParticipantsSync.new(session: session_record, allow_private_coaching: true, bypass_deadline: true)
      append_flash_alert(sync.call(params.dig(:session, :participant_ids)))
    end

    def create_on_all_terrains
      authorize! :manage, Session

      errors = Sessions::AllTerrainsCreation.new(session_params.to_h).call do |session|
        session.sync_level_priorities(params.dig(:session, :level_priorities))
        sync_participants(session)
      end

      if errors.empty?
        redirect_to admin_sessions_path, notice: "3 sessions créées (terrains 1, 2, 3)."
      else
        # Re-render with errors on the main @session instance for feedback
        @session.assign_attributes(session_params)
        @session.errors.add(:base, errors.join("; "))
        render :new, status: :unprocessable_entity
      end
    end
  end
end
