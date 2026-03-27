# frozen_string_literal: true

class TerrainClosure < ApplicationRecord
  ALLOWED_TERRAINS = Session.terrains.keys.freeze

  validates :terrain, :starts_on, :ends_on, presence: true
  validate :terrain_in_allowed_list
  validate :ends_on_not_before_starts_on

  scope :for_date, ->(date) {
    d = date.respond_to?(:to_date) ? date.to_date : date
    where("starts_on <= ? AND ends_on >= ?", d, d)
  }

  # Closures that overlap [range_start, range_end] (inclusive dates).
  scope :intersecting_range, ->(range_start, range_end) {
    rs = range_start.respond_to?(:to_date) ? range_start.to_date : range_start
    re = range_end.respond_to?(:to_date) ? range_end.to_date : range_end
    where("starts_on <= ? AND ends_on >= ?", re, rs)
  }

  scope :for_forms_upcoming, -> {
    today = Time.zone.today
    horizon = today + 6.months
    intersecting_range(today, horizon).order(:starts_on, :terrain)
  }

  def self.covers?(terrain:, date:)
    return false if terrain.blank? || date.blank?

    d = date.respond_to?(:to_date) ? date.to_date : date
    for_date(d).where(terrain: terrain).exists?
  end

  def self.unavailable_terrain_keys_for_date(date)
    for_date(date).distinct.pluck(:terrain)
  end

  def self.as_json_for_forms
    for_forms_upcoming.map do |c|
      {
        terrain: c.terrain,
        starts_on: c.starts_on.iso8601,
        ends_on: c.ends_on.iso8601,
        reason: c.reason.presence
      }
    end
  end

  private

  def terrain_in_allowed_list
    return if terrain.blank?

    errors.add(:terrain, "n'est pas un terrain valide") unless ALLOWED_TERRAINS.include?(terrain)
  end

  def ends_on_not_before_starts_on
    return if starts_on.blank? || ends_on.blank?
    return if ends_on >= starts_on

    errors.add(:ends_on, "doit être postérieure ou égale à la date de début")
  end
end
