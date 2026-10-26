# frozen_string_literal: true

class TerrainClosure < ApplicationRecord
  # La colonne historique `terrain` (nom) reste en base jusqu'à la migration
  # « contract » : elle n'est plus lue, mais tenue à jour pour que l'ancien
  # code reste redéployable (cf. Terrains::LegacyColumns).
  belongs_to :terrain
  before_save { Terrains::LegacyColumns.write_closure(self) }

  validates :starts_on, :ends_on, presence: true
  validates :ends_on, after: { start: :starts_on, allow_equal: true, message: "doit être postérieure ou égale à la date de début" }

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
    intersecting_range(today, horizon).order(:starts_on, :terrain_id)
  }

  def self.covers?(terrain_id:, date:)
    return false if terrain_id.blank? || date.blank?

    d = date.respond_to?(:to_date) ? date.to_date : date
    for_date(d).where(terrain_id: terrain_id).exists?
  end

  def self.as_json_for_forms
    for_forms_upcoming.includes(:terrain).map do |c|
      {
        terrain_id: c.terrain_id,
        terrain: c.terrain.name,
        starts_on: c.starts_on.iso8601,
        ends_on: c.ends_on.iso8601,
        reason: c.reason.presence
      }
    end
  end
end
