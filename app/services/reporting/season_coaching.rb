# frozen_string_literal: true

module Reporting
  # Entraînements donnés par les coachs sur une saison, et ce qu'ils coûtent.
  class SeasonCoaching
    Row = Data.define(:coach, :count, :amount_eur)

    def initialize(months)
      @months = months
    end

    def comparisons
      compare = SeasonComparisons.new(self, self.class.new(@months.previous))
      [
        compare.compare(:trainings, "Entraînements", "dumbbell") { |report| report.trainings.count },
        compare.compare(:salaries, "Salaires coachs", "wallet", unit: "€", higher_is_better: false, &:salaries_eur),
        compare.compare(:coaches, "Coachs actifs", "users") { |report| report.rows.size }
      ]
    end

    # Séries Chartkick des entraînements, une par coach (les plus actifs d'abord).
    def trainings_by_coach
      counts = @months.group(trainings, "sessions.start_at", by: "sessions.user_id")
      rows.map { |row| { name: row.coach.full_name, data: @months.series_for(counts, row.coach.id) } }
    end

    def rows
      @rows ||= begin
        counts = trainings.group(:user_id).count
        User.where(id: counts.keys).map do |coach|
          Row.new(coach: coach, count: counts[coach.id], amount_eur: counts[coach.id] * coach.salary_per_training_cents.to_i / 100)
        end.sort_by { |row| -row.count }
      end
    end

    def trainings = Session.held.trainings.where(start_at: @months.range)

    def salaries_eur = rows.sum(&:amount_eur)
  end
end
