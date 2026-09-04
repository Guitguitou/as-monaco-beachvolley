# frozen_string_literal: true

module Me
  class SessionsController < ApplicationController
    before_action :authenticate_user!

    def index
      @list = SessionsList.new(user: current_user, filter: params[:filter])
    end

    def show
      # Volontairement sur les registrations et non sur `sessions_registered` :
      # une session où le joueur est en liste d'attente doit rester ouvrable.
      registration = Registration.find_by!(user_id: current_user.id, session_id: params[:id])
      @session = registration.session
    end
  end
end
