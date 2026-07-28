class AnnonceSlot < ApplicationRecord
  belongs_to :annonce
  has_many :availabilities, class_name: "AnnonceAvailability", dependent: :destroy
  has_many :available_users, through: :availabilities, source: :user

  validates :start_at, :end_at, presence: true
  validate :end_at_after_start_at

  scope :ordered_by_start, -> { order(:start_at) }

  private

  def end_at_after_start_at
    return if start_at.blank? || end_at.blank?
    return if end_at > start_at

    errors.add(:end_at, "doit être après la date de début")
  end
end
