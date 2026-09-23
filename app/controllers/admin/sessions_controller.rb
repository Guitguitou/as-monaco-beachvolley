# frozen_string_literal: true

module Admin
  class SessionsController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
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
      old_start = @session.start_at
      @session.assign_attributes(session_params)
      recalculate_deadlines_on_reschedule(old_start)

      if @session.save
        max_players_changed = @session.saved_change_to_max_players?
        @session.sync_level_priorities(params.dig(:session, :level_priorities))
        # Only sync participants if the form included participant_ids to avoid unintended removals
        sync_participants(@session) if params.dig(:session, :participant_ids).present?
        # Rééquilibrer uniquement si le nombre de places ou les groupes ont pu changer
        rebalance_after_edit = max_players_changed || params.dig(:session, :level_priorities).present? || params.dig(:session, :level_ids).present?
        @session.rebalance! if @session.entrainement? && rebalance_after_edit

        notice = "Session mise à jour avec succès."
        if scope_param == "following" && @session.has_following_in_series?
          result = Sessions::SeriesUpdateService.call(
            edited_session: @session, old_start: old_start, scope: "following"
          )
          notice = "Session et #{result[:updated_count]} suivante(s) mises à jour ✅"
          flash[:alert] = [ "Certaines sessions n'ont pas pu être mises à jour :", *result[:failures] ].join("\n") if result[:failures].any?
        end

        redirect_to admin_session_path(@session), notice: notice
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      result = Sessions::SeriesDestroyService.call(session: @session, scope: scope_param)

      notice =
        if scope_param == "following" && result[:destroyed_count] > 1
          "#{result[:destroyed_count]} session(s) supprimée(s) et remboursée(s) ✅"
        else
          "Session supprimée avec succès."
        end
      flash[:alert] = [ "Certaines suppressions ont échoué :", *result[:failures] ].join("\n") if result[:failures].any?

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

    # Portée d'une action multi-sessions : "this" (défaut) ou "following".
    def scope_param
      %w[this following].include?(params[:scope]) ? params[:scope] : "this"
    end

    # Si la date de début change et que l'admin n'a pas modifié manuellement les
    # deadlines, on les décale du même delta pour garder la cohérence (ouverture
    # des inscriptions, date limite de désinscription). La deadline 17h jour J
    # est dérivée à la volée et suit start_at automatiquement.
    def recalculate_deadlines_on_reschedule(old_start)
      return unless @session.start_at_changed? && old_start.present? && @session.start_at.present?

      delta = @session.start_at - old_start
      if @session.cancellation_deadline_at.present? && !@session.cancellation_deadline_at_changed?
        @session.cancellation_deadline_at += delta
      end
      if @session.registration_opens_at.present? && !@session.registration_opens_at_changed?
        @session.registration_opens_at += delta
      end
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

      base_attrs = session_params.to_h
      base_attrs.delete("terrain")

      created = []
      errors = []

      ActiveRecord::Base.transaction do
        %w[Terrain\ 1 Terrain\ 2 Terrain\ 3].each do |terrain_label|
          s = Session.new(base_attrs)
          s.terrain = terrain_label
          unless s.save
            errors << s.errors.full_messages.to_sentence
            raise ActiveRecord::Rollback
          end
          s.sync_level_priorities(params.dig(:session, :level_priorities))
          created << s
          sync_participants(s)
        end
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
