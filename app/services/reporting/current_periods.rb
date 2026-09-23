# frozen_string_literal: true

module Reporting
  # Semaine, mois et année en cours, tels que les comptent les bilans coach et
  # les filtres de l'admin. La semaine court du lundi au lundi suivant inclus.
  module CurrentPeriods
    def self.ranges(now: Time.zone.now)
      week_start = now.to_date.beginning_of_week
      {
        week: week_start..(week_start + 7.days),
        month: now.beginning_of_month..now.end_of_month,
        year: now.beginning_of_year..now.end_of_year
      }
    end
  end
end
