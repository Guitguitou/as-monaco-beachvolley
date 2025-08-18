# frozen_string_literal: true

module Admin
  class SessionsController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    load_and_authorize_resource
    before_action :set_session, only: [:show, :edit, :update, :destroy]

    def index
      @sessions = @sessions.order(start_at: :desc)
    end

    def show
    end

    def new
      @session = Session.new
    end

    def create
      @session = Session.new(session_params)

      if @session.save
        sync_participants(@session)
        redirect_to admin_session_path(@session), notice: "Session créée avec succès."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @levels = Level.all
    end

    def update
      @session.assign_attributes(session_params)
      if @session.save
        sync_participants(@session)
        redirect_to admin_session_path(@session), notice: "Session mise à jour avec succès."
      else
        render :edit, status: :unprocessable_entity
        flash.now[:alert] = "Erreur lors de la mise à jour de la session: #{@session.errors.full_messages.join(', ')}"
      end
    end

    def destroy
      @session.destroy
      redirect_to admin_sessions_path, notice: "Session supprimée avec succès."
    end

    private

    def set_session
      @session = Session.find(params[:id])
    end

    def session_params
      params.require(:session).permit(:title, :description, :start_at, :end_at, :session_type, :max_players, :terrain, :user_id, :price, level_ids: [], participant_ids: [])
    end

    # Authorization handled by CanCanCan

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
          session_record.promote_from_waitlist!
        end
      end

      flash[:alert] = [flash[:alert], errors.join("; ")].compact.reject(&:blank?).join("; ") if errors.any?
    end
  end
end
