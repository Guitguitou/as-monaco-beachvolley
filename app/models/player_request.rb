class PlayerRequest < ApplicationRecord
  belongs_to :player_listing
  belongs_to :from_user, class_name: "User"
  belongs_to :to_user, class_name: "User"

  enum :status, {
    pending: "pending",
    accepted: "accepted",
    declined: "declined"
  }

  validates :status, presence: true
  validate :different_users

  private

  def different_users
    return if from_user_id.blank? || to_user_id.blank?
    return if from_user_id != to_user_id

    errors.add(:to_user_id, "ne peut pas être le même utilisateur")
  end
end
