# frozen_string_literal: true

# Saison du club (cf. GLOSSARY.md) : un an à partir du mois de début de saison
# (septembre par défaut, réglable dans les Règles du club). La remise à zéro
# des licences en marque le passage sans la définir.
#
#   Season.current             # saison en cours selon ClubRules.current
#   season.range               # 1er sept. 2026 00:00 .. 31 août 2027 23:59
#   season.label               # "2026-2027"
class Season < Data.define(:starts_on)
  def self.current(rules: ClubRules.current) = containing(Date.current, start_month: rules.season_start_month)

  def self.containing(date, start_month:)
    year = date.month >= start_month ? date.year : date.year - 1
    new(starts_on: Date.new(year, start_month, 1))
  end

  def ends_on = starts_on.next_year - 1

  def range = starts_on.in_time_zone.beginning_of_day..ends_on.in_time_zone.end_of_day

  def label = starts_on.month == 1 ? starts_on.year.to_s : "#{starts_on.year}-#{starts_on.year + 1}"

  def previous = with(starts_on: starts_on.prev_year)

  # Premier jour de chacun des douze mois de la saison.
  def months = (0..11).map { |offset| starts_on >> offset }

  def cover?(date) = (starts_on..ends_on).cover?(date.to_date)
end
