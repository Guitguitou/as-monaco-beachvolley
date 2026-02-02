class PlayerListing < ApplicationRecord
  belongs_to :user
  belongs_to :session, optional: true

  has_many :player_listing_levels, dependent: :destroy
  has_many :levels, through: :player_listing_levels
  has_many :player_requests, dependent: :destroy

  enum :listing_type, {
    disponible: "disponible",
    recherche: "recherche"
  }

  enum :status, {
    active: "active",
    closed: "closed"
  }

  enum :gender, {
    male: "male",
    female: "female",
    mixed: "mixed"
  }, prefix: true

  validates :listing_type, :status, presence: true
  validates :date, presence: true, if: -> { session.blank? }
  validates :starts_at, :ends_at, presence: true, if: -> { session.blank? }
  validate :end_after_start

  before_validation :apply_session_defaults

  def effective_date
    date || session&.start_at&.to_date
  end

  def effective_start_at
    build_time_from(effective_date, starts_at || session&.start_at)
  end

  def effective_end_at
    build_time_from(effective_date, ends_at || session&.end_at)
  end

  def effective_level_ids
    return level_ids if level_ids.any?
    session ? session.level_ids : []
  end

  private

  def apply_session_defaults
    return unless session

    self.date ||= session.start_at&.to_date
    self.starts_at ||= session.start_at&.to_time
    self.ends_at ||= session.end_at&.to_time
  end

  def build_time_from(base_date, time_value)
    return nil if base_date.blank? || time_value.blank?

    time = time_value.respond_to?(:hour) ? time_value : Time.zone.parse(time_value.to_s)
    return nil if time.blank?

    Time.zone.local(base_date.year, base_date.month, base_date.day, time.hour, time.min)
  end

  def end_after_start
    start_time = effective_start_at
    end_time = effective_end_at
    return if start_time.blank? || end_time.blank?

    if end_time <= start_time
      errors.add(:ends_at, "doit être après l'heure de début")
    end
  end
end
