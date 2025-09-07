# frozen_string_literal: true
module Admin
  class DashboardController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    before_action :require_admin!

    def index
      @presenter = Admin::DashboardPresenter.new

      @upcoming_trainings = @presenter.upcoming_trainings_for_week(@presenter.week_start)
      @upcoming_free_plays = @presenter.upcoming_free_plays
      @upcoming_private_coachings = @presenter.upcoming_private_coachings

      @current_month_revenue = @presenter.current_month_revenue

      # Coach salaries (expected) for periods
      @coach_salary_week = @presenter.coach_salary_for_period(@presenter.week_start..(@presenter.week_start + 7.days))
      @coach_salary_month = @presenter.coach_salary_for_period(@presenter.month_start..@presenter.month_start.end_of_month)
      @coach_salary_year = @presenter.coach_salary_for_period(@presenter.year_start..@presenter.year_start.end_of_year)

      @coach_breakdown = @presenter.coach_salary_breakdown(
        week_range: @presenter.week_start..(@presenter.week_start + 7.days),
        month_range: @presenter.month_start..@presenter.month_start.end_of_month,
        year_range: @presenter.year_start..@presenter.year_start.end_of_year
      )

      @late_cancellations = @presenter.recent_late_cancellations
      @late_cancellation_counts = @presenter.late_cancellation_counts

      # Charges et revenus
      @weekly_charges = @presenter.weekly_charges
      @monthly_charges = @presenter.monthly_charges
      @weekly_revenue = @presenter.weekly_revenue
      @monthly_revenue = @presenter.monthly_revenue
      @weekly_net_profit = @presenter.weekly_net_profit
      @monthly_net_profit = @presenter.monthly_net_profit

      # Breakdowns pour le tableau détaillé
      @weekly_charges_breakdown = @presenter.charges_breakdown(@presenter.week_start..(@presenter.week_start + 7.days))
      @monthly_charges_breakdown = @presenter.charges_breakdown(@presenter.month_start..@presenter.month_start.end_of_month)
      @weekly_revenue_breakdown = @presenter.revenue_breakdown(@presenter.week_start..(@presenter.week_start + 7.days))
      @monthly_revenue_breakdown = @presenter.revenue_breakdown(@presenter.month_start..@presenter.month_start.end_of_month)
    end

    private

    def require_admin!
      redirect_to root_path, alert: "Accès non autorisé" unless current_user&.admin?
    end
  end
end
