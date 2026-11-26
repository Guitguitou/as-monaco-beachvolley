class AnnonceSlot < ApplicationRecord
  belongs_to :annonce
  has_many :availabilities, class_name: "AnnonceAvailability", dependent: :destroy
  has_many :available_users, through: :availabilities, source: :user

  validates :start_at, :end_at, presence: true
  validates :end_at, after: { start: :start_at, message: "doit être après la date de début" }

  scope :ordered_by_start, -> { order(:start_at) }
  scope :upcoming, -> { where("annonce_slots.start_at > ?", Time.current) }

  def upcoming?
    start_at.present? && start_at > Time.current
  end

  # Joueurs qu'il manque pour que ce créneau atteigne le quota de l'annonce.
  def missing_players
    [ annonce.min_players - availabilities.size, 0 ].max
  end

  def quota_reached?
    missing_players.zero?
  end

  def overlaps?(range_start, range_end)
    start_at < range_end && end_at > range_start
  end
end
