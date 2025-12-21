# frozen_string_literal: true

module Admin
  class SessionsController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    load_and_authorize_resource
    before_action :set_session, only: [ :show, :edit, :update, :destroy, :duplicate ]

    def index
      filters = {
        coach_id: params[:coach_id],
        period: params[:period],
        start_at_from: params[:start_at_from],
        start_at_to: params[:start_at_to]
      }
      @sessions = SessionFilterService.new(@sessions, filters).call
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
      @session.assign_attributes(session_params)
      if @session.save
        # Only sync participants if the form included participant_ids to avoid unintended removals
        sync_participants(@session) if params.dig(:session, :participant_ids).present?
        redirect_to admin_session_path(@session), notice: "Session mise à jour avec succès."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @session.destroy
      redirect_to admin_sessions_path, notice: "Session supprimée avec succès."
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

    def session_params
      params.require(:session).permit(
        :title, :description, :start_at, :end_at, :session_type, :max_players, :terrain, :user_id, :price,
        :cancellation_deadline_at, :registration_opens_at, :coach_notes,
        level_ids: [], participant_ids: []
      )
    end

    # Authorization handled by CanCanCan

    def sync_participants(session_record)
      participant_ids = params.dig(:session, :participant_ids)
      result = SyncParticipantsService.new(
        session_record,
        participant_ids,
        can_manage_registrations: true,
        can_bypass_deadline: true
      ).call

      if result[:errors].any?
        flash[:alert] = [ flash[:alert], result[:errors].join("; ") ].compact.reject(&:blank?).join("; ")
      end
    end

    def create_on_all_terrains
      authorize! :manage, Session

      participant_ids = params.dig(:session, :participant_ids)
      service = CreateSessionsOnAllTerrainsService.new(session_params, participant_ids, current_user)
      result = service.call

      if result[:success]
        redirect_to admin_sessions_path, notice: "3 sessions créées (terrains 1, 2, 3)."
      else
        @session.assign_attributes(session_params)
        @session.errors.add(:base, result[:errors].join("; "))
        render :new, status: :unprocessable_entity
      end
    end
  end
end
