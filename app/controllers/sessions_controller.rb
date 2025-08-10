# frozen_string_literal: true

class SessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session, only: [:show, :edit, :update, :destroy]

  def index
    @sessions = Session.order(start_at: :desc)
    @sessions = @sessions.terrain(params[:terrain]) if params[:terrain].present?
  end

  def show
  end

  def new
    @session = Session.new
  end

  def create
    @session = Session.new(session_params)

    if @session.save
      redirect_to sessions_path, notice: "Session créée avec succès."
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

  private

  def set_session
    @session = Session.find(params[:id])
  end

  def session_params
    params.require(:session).permit(
      :title, :description, :start_at, :end_at, 
      :session_type, :max_players, :terrain, :user_id, :price,
      registrations_attributes: [:id, :user_id, :_destroy],
      level_ids: []
    )
  end

  def ensure_admin!
    redirect_to root_path, alert: "Accès refusé" unless current_user.admin?
  end
end
