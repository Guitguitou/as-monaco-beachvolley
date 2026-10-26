class AnnonceAvailability < ApplicationRecord
  belongs_to :annonce_slot
  belongs_to :user

  validates :user_id, uniqueness: { scope: :annonce_slot_id }

  # Créneaux de l'annonce sur lesquels le joueur s'est déclaré disponible.
  def self.slot_ids_for(annonce:, user:)
    where(annonce_slot_id: annonce.slots.select(:id), user_id: user.id).pluck(:annonce_slot_id).to_set
  end
end
