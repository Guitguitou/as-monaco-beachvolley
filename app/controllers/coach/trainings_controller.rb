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
        load_my_trainings_data
      end
    end

    private

    def load_library_data
      service = TrainingLibraryService.new(current_user, only_mine: params[:only_mine].present?)
      result = service.call
      @by_level_id = result[:by_level_id]
      @levels = result[:levels]
    end

    def load_my_trainings_data
      service = CoachDataService.new(current_user)

      counts = service.training_counts
      salaries = service.salaries

      @my_trainings_week_count = counts[:week]
      @my_trainings_month_count = counts[:month]
      @my_trainings_year_count = counts[:year]
      @my_salary_week = salaries[:week]
      @my_salary_month = salaries[:month]
      @my_salary_year = salaries[:year]

      @past_trainings = service.past_trainings
      @upcoming_trainings = service.upcoming_trainings
      @monthly_salary_data = service.monthly_salary_data
    end

    def ensure_coach_or_admin!
      redirect_to root_path, alert: "Accès réservé aux coachs/admins" unless current_user.admin? || current_user.coach?
    end
  end
end
