# frozen_string_literal: true

module Admin
  class SessionsController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    load_and_authorize_resource
    before_action :set_session, only: [:show, :edit, :update, :destroy, :duplicate]

    def index
      # Optional filters
      if params[:coach_id].present?
        @sessions = @sessions.where(user_id: params[:coach_id])
      end

      if params[:period].present?
        range = case params[:period]
                when 'week'
                  Time.zone.today.beginning_of_week..(Time.zone.today.beginning_of_week + 7.days)
                when 'month'
                  Time.zone.now.beginning_of_month..Time.zone.now.end_of_month
                when 'year'
                  Time.zone.now.beginning_of_year..Time.zone.now.end_of_year
                else
                  nil
                end
        @sessions = @sessions.where(start_at: range) if range
      else
        from = params[:start_at_from].presence && Time.zone.parse(params[:start_at_from]) rescue nil
        to   = params[:start_at_to].presence && Time.zone.parse(params[:start_at_to]) rescue nil
        if from && to
          @sessions = @sessions.where(start_at: from..to)
        elsif from
          @sessions = @sessions.where('start_at >= ?', from)
        elsif to
          @sessions = @sessions.where('start_at <= ?', to)
        end
      end

      @sessions = @sessions.order(start_at: :desc)
    end

    def show
    end

    def new
      @session = Session.new
    end

    def create
      @session = Session.new(session_params)

      if params.dig(:session, :create_on_all_terrains) == '1'
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
          ["Certaines duplications ont échoué:", *result[:errors]].join("\n") :
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
        flash[:alert] = [flash[:alert], result[:errors].join("; ")].compact.reject(&:blank?).join("; ")
      end
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
