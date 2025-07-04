# frozen_string_literal: true

module Admin
  class SessionsController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    before_action :ensure_admin!
    before_action :set_session, only: [:show, :edit, :update]

    def index
      @sessions = Session.order(start_at: :desc)
    end

    def show
    end

    def new
      @session = Session.new
    end

    def create
      @session = Session.new(session_params)
      @session.user = resolve_session_owner(@session.session_type)

      if @session.save
        redirect_to admin_session_path(@session), notice: "Session créée avec succès."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      @session.assign_attributes(session_params)
      @session.user = resolve_session_owner(@session.session_type)

      if @session.save
        redirect_to admin_session_path(@session), notice: "Session mise à jour avec succès."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_session
      @session = Session.find(params[:id])
    end

    def session_params
      params.require(:session).permit(:title, :description, :start_at, :end_at, :session_type, :max_players)
    end

    # 👇 Attribution automatique du user responsable de la session
    def resolve_session_owner(type)
      case type
      when "entrainement", "coaching_prive"
        User.where(coach: true).first
      when "jeu_libre"
        User.where(responsable: true).first
      when "tournoi"
        User.where(admin: true).first
      else
        current_user
      end
    end

    def ensure_admin!
      redirect_to root_path, alert: "Accès refusé" unless current_user.admin?
    end
  end
end
