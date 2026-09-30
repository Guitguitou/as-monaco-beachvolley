# frozen_string_literal: true

module Admin
  class FinancesController < BaseController
    before_action :require_admin_or_financial_manager!

    def show
      ranges = SessionsPeriod.current_ranges
      revenue_service = Reporting::Revenue.new

      @revenues = revenue_service.period_revenues
      @coach_salaries = ranges.transform_values { |range| Reporting::CoachSalaries.new.total_for_period(range) }
      @breakdowns = {
        sessions: revenue_service.session_breakdown_by_type(ranges[:month]),
        packs: revenue_service.pack_breakdown_by_type(ranges[:month])
      }
      @monthly_revenue = Reporting::PacksStats.new.last_months_stats(12)

      @players_period = SessionsPeriod.new(params[:period].presence || "month", params[:period_anchor])
      @player_spending = Reporting::PlayerSessionSpending.new(@players_period.range)
    end
  end
end
