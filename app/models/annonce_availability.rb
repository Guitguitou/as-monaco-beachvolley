class AnnonceAvailability < ApplicationRecord
  belongs_to :annonce_slot
  belongs_to :user

  validates :user_id, uniqueness: { scope: :annonce_slot_id }
end
