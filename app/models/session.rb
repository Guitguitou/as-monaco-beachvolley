class Session < ApplicationRecord
  belongs_to :user
  has_many :session_levels, dependent: :destroy
  has_many :levels, through: :session_levels
  has_many :registrations, dependent: :destroy
  has_many :participants, through: :registrations, source: :user
  validates :title, :start_at, :end_at, :session_type, :user_id, :terrain, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  accepts_nested_attributes_for :registrations, allow_destroy: true

  enum :session_type, {
    entrainement: "entrainement",
    jeu_libre: "jeu_libre",
    tournoi: "tournoi",
    coaching_prive: "coaching_prive"
  }

  enum :terrain, {
    "Terrain 1": 1,
    "Terrain 2": 2,
    "Terrain 3": 3
  }

  before_validation :set_price_from_type

  validate :end_at_after_start_at
  validate :no_overlapping_sessions_on_same_terrain
  validate :validate_unique_participants
  validate :validate_max_registrations
  validate :coach_has_enough_credits_for_private_coaching, if: :coaching_prive?

  after_create :charge_coach_for_private_coaching, if: :coaching_prive?

  scope :terrain, ->(terrain) { where(terrain: terrain) }

  def display_name
    case session_type
    when "entrainement"
      title + " - " + levels.map(&:display_name).join(", ")
    when "jeu_libre"
      title
    when "tournoi"
      title
    when "coaching_prive"
      title
    else
      title
    end
  end

  def full?
    registrations.count >= max_players if max_players.present?
  end

  private

  def set_price_from_type
    self.price = default_price
  end

  def default_price
    case session_type
    when "entrainement" then 350
    when "jeu_libre" then 300
    when "coaching_prive" then 1500
    else 0
    end
  end

  def end_at_after_start_at
    return if end_at.blank? || start_at.blank?

    if end_at <= start_at
      errors.add(:end_at, "doit être après la date de début")
    end
  end

  def no_overlapping_sessions_on_same_terrain
    return if start_at.blank? || end_at.blank? || terrain.blank?

    overlapping_sessions = Session.where(terrain: terrain)
                                .where.not(id: id)
                                .where(
                                  "(start_at < ? AND end_at > ?) OR " \
                                  "(start_at < ? AND end_at > ?) OR " \
                                  "(start_at >= ? AND end_at <= ?)",
                                  end_at, start_at,
                                  end_at, start_at,
                                  start_at, end_at
                                )

    if overlapping_sessions.exists?
      errors.add(:base, "Une session existe déjà sur ce terrain pendant ces horaires")
    end
  end

  def validate_unique_participants
    ids = registrations.reject(&:marked_for_destruction?).map(&:user_id)
    if ids.uniq.length != ids.length
      errors.add(:registrations, "ne peut participer qu'une seule fois à une session")
    end
  end

  def validate_max_registrations
    if max_players.present? && registrations.count > max_players
      errors.add(:registrations, "le nombre de participants ne peut pas dépasser #{max_players}")
    end
  end

  def coach_has_enough_credits_for_private_coaching
    return if user&.balance&.amount.to_i >= default_price

    errors.add(:base, "Le coach n'a pas assez de crédits pour créer un coaching privé (#{default_price} requis)")
  end

  def charge_coach_for_private_coaching
    TransactionService.new(user, self, default_price).create_transaction
  end
end
