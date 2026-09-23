# frozen_string_literal: true

module Reporting
  class CoachStats
    def initialize(time_zone: "Europe/Paris")
      @time_zone = time_zone
      @current_time = Time.current.in_time_zone(@time_zone)
    end

    # Chaque mois de l'année en cours jusqu'au mois courant, le plus récent en premier.
    def monthly_stats_for_current_year
      coaches = active_coaches
      (0...@current_time.month).map do |offset|
        month = @current_time.beginning_of_year + offset.months
        period_stats(month.all_month, coaches).merge(
          period: I18n.l(month, format: :month_and_year), period_short: month.strftime("%m/%Y"),
          month: month.month, year: month.year
        )
      end.reverse
    end

    # Chaque année depuis le premier entraînement, la plus récente en premier.
    def yearly_stats
      first_start = Session.trainings.minimum(:start_at)
      return [] unless first_start

      coaches = active_coaches
      (first_start.year..@current_time.year).map do |year|
        period_stats(Time.zone.local(year).in_time_zone(@time_zone).all_year, coaches).merge(period: year.to_s, year: year)
      end.reverse
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

    # Entraînements et salaire de chaque coach sur la période, et leurs totaux.
    def period_stats(range, coaches)
      counts = Session.trainings.where(start_at: range).group(:user_id).count
      by_coach = coaches.to_h do |coach|
        count = counts[coach.id] || 0
        [ coach.id, { coach: coach, count: count, amount: count * (coach.salary_per_training_cents || 0) / 100.0 } ]
      end
      rows = by_coach.values
      { by_coach: by_coach, total_sessions: rows.sum { |row| row[:count] }, total_amount: rows.sum { |row| row[:amount] }, range: range }
    end
  end
end
