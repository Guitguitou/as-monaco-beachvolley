class AnnonceSlot < ApplicationRecord
  belongs_to :annonce
  has_many :availabilities, class_name: "AnnonceAvailability", dependent: :destroy
  has_many :available_users, through: :availabilities, source: :user

  validates :start_at, :end_at, presence: true
  validates :end_at, after: { start: :start_at, message: "doit être après la date de début" }

  scope :ordered_by_start, -> { order(:start_at) }
end
