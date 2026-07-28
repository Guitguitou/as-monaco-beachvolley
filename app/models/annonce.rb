class Annonce < ApplicationRecord
  belongs_to :user
  belongs_to :session, optional: true

  has_many :annonce_levels, dependent: :destroy
  has_many :levels, through: :annonce_levels
  has_many :slots, class_name: "AnnonceSlot", dependent: :destroy

  accepts_nested_attributes_for :slots, allow_destroy: true, reject_if: :all_blank

  enum :status, { open: 0, confirmed: 1, cancelled: 2 }

  validates :title, presence: true
  validates :min_players, numericality: { greater_than_or_equal_to: 1 }
  validate :at_least_one_slot

  scope :ordered_by_recent, -> { order(created_at: :desc) }

  # Créneaux ayant atteint le quota minimum de joueurs disponibles.
  def confirmable_slots
    slots.select { |slot| slot.availabilities.size >= min_players }
  end

  # Vrai si au moins un créneau atteint le quota (annonce confirmable).
  def confirmable?
    open? && confirmable_slots.any?
  end

  # Badge indicatif : un responsable figure-t-il parmi les joueurs dispos sur ce créneau ?
  def responsable_present?(slot)
    slot.available_users.any?(&:responsable?)
  end

  # Nombre de joueurs distincts ayant répondu (au moins une dispo).
  def participant_count
    AnnonceAvailability.where(annonce_slot_id: slots.select(:id)).distinct.count(:user_id)
  end

  private

  def at_least_one_slot
    return unless slots.reject(&:marked_for_destruction?).empty?

    errors.add(:base, "Une annonce doit proposer au moins un créneau")
  end
end
