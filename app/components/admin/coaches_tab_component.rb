# frozen_string_literal: true

module Admin
  class CoachesTabComponent < ViewComponent::Base
    def initialize(coach_breakdown:, upcoming_sessions_by_coach:)
      @coach_breakdown = coach_breakdown
      @upcoming_sessions_by_coach = upcoming_sessions_by_coach
    end

    private

    attr_reader :coach_breakdown, :upcoming_sessions_by_coach

    def format_currency(amount)
      number_with_precision(amount, precision: 2)
    end

    def upcoming_sessions_for_coach(coach)
      upcoming_sessions_by_coach[coach.id] || []
    end

    def total_hours_for_coach(coach, period)
      case period
      when :week
        coach[:week_count] * 1.5 # Estimation 1.5h par session
      when :month
        coach[:month_count] * 1.5
      when :year
        coach[:year_count] * 1.5
      else
        0
      end
    end

    def average_per_session(coach, period)
      case period
      when :week
        coach[:week_count] > 0 ? coach[:week_amount] / coach[:week_count] : 0
      when :month
        coach[:month_count] > 0 ? coach[:month_amount] / coach[:month_count] : 0
      when :year
        coach[:year_count] > 0 ? coach[:year_amount] / coach[:year_count] : 0
      else
        0
      end
    end
  end
end
