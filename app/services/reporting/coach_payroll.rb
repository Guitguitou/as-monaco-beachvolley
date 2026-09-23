# frozen_string_literal: true

module Reporting
  # Entraînements et salaire d'un coach : compteurs sur les périodes usuelles,
  # historique mensuel et prochaines sessions.
  class CoachPayroll
    def initialize(coach, now: Time.current)
      @coach = coach
      @now = now
      @salary_cents = coach.salary_per_training_cents.to_i
    end

    def periods(ranges)
      ranges
        .transform_values { |range| priced(trainings.where(start_at: range).count) }
        .merge(salary_per_training: @salary_cents / 100.0)
    end

    def current_periods
      periods(CurrentPeriods.ranges(now: @now))
    end

    # Une seule requête groupée pour tous les mois.
    def monthly_history(months: 12)
      first_month = (@now - (months - 1).months).beginning_of_month
      counts = trainings.where(start_at: first_month..@now.end_of_month)
                        .group(Arel.sql("DATE_TRUNC('month', start_at)")).count
                        .transform_keys { |time| time.to_date.beginning_of_month }

      (0...months).map do |offset|
        month = (first_month + offset.months).to_date
        count = counts[month].to_i
        { month_name: I18n.l(month, format: :month_and_year), training_count: count, total_salary: priced(count)[:amount] }
      end
    end

    def upcoming_sessions(limit: 5)
      trainings.upcoming.includes(:registrations, :levels).ordered_by_start.limit(limit)
    end

    private

    def trainings
      Session.trainings.where(user_id: @coach.id)
    end

    def priced(count)
      { count: count, amount: (@salary_cents * count) / 100.0 }
    end
  end
end
