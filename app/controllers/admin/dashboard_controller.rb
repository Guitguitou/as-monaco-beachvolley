# frozen_string_literal: true
module Admin
  class DashboardController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    before_action :require_admin!

    def index
    end

    private

    def require_admin!
      redirect_to root_path, alert: "Accès non autorisé" unless current_user.admin?
    end
  end
end
