# frozen_string_literal: true

module Reporting
  class CoachSalaries
    # Total des salaires pour une période
    def total_for_period(range)
      Reporting::CacheService.fetch("coach_salaries", "total_for_period", range.first.to_date, range.last.to_date) do
        sessions = Session.trainings.where(start_at: range)
        by_coach_counts = sessions.group(:user_id).count

        return 0 if by_coach_counts.empty?

        users = User.where(id: by_coach_counts.keys).index_by(&:id)
        total_cents = by_coach_counts.sum do |user_id, count|
          (users[user_id]&.salary_per_training_cents || 0) * count
        end

        total_cents / 100.0
      end
    end

    # Compteurs et montants de chaque coach sur les trois périodes, le mieux
    # payé du mois en premier.
    def breakdown(ranges)
      counts = ranges.transform_values { |range| Session.trainings.where(start_at: range).group(:user_id).count }
      User.where(id: counts.values.flat_map(&:keys).uniq).map { |user| coach_breakdown(user, counts) }.sort_by { |row| -row[:month_amount] }
    end

    private

    def coach_breakdown(user, counts)
      salary_cents = user.salary_per_training_cents.to_i
      counts.each_with_object({ user: user, salary_per_training: salary_cents / 100.0 }) do |(period, by_coach), row|
        count = by_coach[user.id].to_i
        row[:"#{period}_count"] = count
        row[:"#{period}_amount"] = (salary_cents * count) / 100.0
      end
    end
  end
end
