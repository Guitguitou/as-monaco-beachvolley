# frozen_string_literal: true

# Service pour calculer les plages de dates courantes
# Centralise la logique de calcul des ranges pour éviter la duplication
class DateRangeService
  TIMEZONE = "Europe/Paris".freeze

  def self.week_range
    current_time = Time.current.in_time_zone(TIMEZONE)
    week_start = current_time.beginning_of_week(:monday)
    week_start..week_start.end_of_week(:monday)
  end

  def self.month_range
    current_time = Time.current.in_time_zone(TIMEZONE)
    month_start = current_time.beginning_of_month
    month_start..month_start.end_of_month
  end

  def self.year_range
    current_time = Time.current.in_time_zone(TIMEZONE)
    year_start = current_time.beginning_of_year
    year_start..year_start.end_of_year
  end
end
