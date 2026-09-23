# frozen_string_literal: true

module Coach
  class TrainingsController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_coach_or_admin!

    def index
      @active_tab = params[:tab] || "library"

      case @active_tab
      when "library"
        load_library_data
      when "my_trainings"
        @report = TrainingsReport.new(coach: current_user)
      end
    end

    private

    def load_library_data
      library = TrainingLibrary.new(user: current_user, only_mine: params[:only_mine].present?)
      @by_level_id = library.by_level_id
      @levels = library.levels
    end

    def ensure_coach_or_admin!
      redirect_to root_path, alert: "Accès réservé aux coachs/admins" unless current_user.admin? || current_user.coach?
    end
  end
end
