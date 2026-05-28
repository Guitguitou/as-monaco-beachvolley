# frozen_string_literal: true

module Reporting
  class CoachStats
    def initialize(time_zone: "Europe/Paris")
      @time_zone = time_zone
      @current_time = Time.current.in_time_zone(@time_zone)
    end

    # Statistiques par mois pour l'année en cours
    def monthly_stats_for_current_year
      year_start = @current_time.beginning_of_year
      year_end = @current_time.end_of_year

      coaches = active_coaches
      stats = []
      current_month = year_start

      while current_month <= year_end && current_month <= @current_time.end_of_month
        month_range = current_month.beginning_of_month..current_month.end_of_month
        stats << monthly_breakdown(month_range, current_month, coaches)
        current_month = current_month.next_month
      end

      stats.reverse # Plus récent en premier
    end

    # Statistiques annuelles (toutes les années avec des sessions)
    def yearly_stats
      first_session = Session.trainings.order(:start_at).first
      return [] unless first_session

      first_year = first_session.start_at.year
      current_year = @current_time.year

      coaches = active_coaches
      stats = []

      (first_year..current_year).each do |year|
        year_start = Time.zone.local(year, 1, 1).in_time_zone(@time_zone)
        year_end = year_start.end_of_year
        year_range = year_start..year_end

        stats << yearly_breakdown(year_range, year, coaches)
      end

      stats.reverse # Plus récent en premier
    end

    # Liste des coachs actifs (qui ont fait au moins une session)
    def active_coaches
      coach_ids = Session.trainings
                        .select(:user_id)
                        .distinct
                        .pluck(:user_id)

      User.where(id: coach_ids, coach: true)
          .order(:first_name, :last_name)
    end

    private

    def monthly_breakdown(month_range, month_date, coaches)
      by_coach = coach_breakdown_for_period(month_range, coaches)
      total_sessions = by_coach.values.sum { |v| v[:count] }
      total_amount = by_coach.values.sum { |v| v[:amount] }

      {
        period: I18n.l(month_date, format: :month_and_year),
        period_short: month_date.strftime("%m/%Y"),
        month: month_date.month,
        year: month_date.year,
        by_coach: by_coach,
        total_sessions: total_sessions,
        total_amount: total_amount,
        range: month_range
      }
    end

    def yearly_breakdown(year_range, year, coaches)
      by_coach = coach_breakdown_for_period(year_range, coaches)
      total_sessions = by_coach.values.sum { |v| v[:count] }
      total_amount = by_coach.values.sum { |v| v[:amount] }

      {
        period: year.to_s,
        year: year,
        by_coach: by_coach,
        total_sessions: total_sessions,
        total_amount: total_amount,
        range: year_range
      }
    end

    def coach_breakdown_for_period(period_range, coaches)
      sessions = Session.trainings
                       .where(start_at: period_range)
                       .group(:user_id)
                       .count

      result = {}
      coaches.each do |coach|
        count = sessions[coach.id] || 0
        salary = (coach.salary_per_training_cents || 0) / 100.0

        result[coach.id] = {
          coach: coach,
          count: count,
          amount: count * salary
        }
      end
      result
    end
  end
end
