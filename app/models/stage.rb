class Stage < ApplicationRecord
  # Associations
  belongs_to :main_coach, class_name: "User", optional: true
  belongs_to :assistant_coach, class_name: "User", optional: true
  has_many :packs, dependent: :nullify

  # Attachments
  has_one_attached :image

  # Validations
  validates :title, presence: true
  validates :starts_on, presence: true
  validates :ends_on, presence: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :ends_on, after: { start: :starts_on, allow_equal: true, message: "doit être après la date de début" }

  # Scopes
  scope :ordered_for_players, -> do
    today = Date.current
    upcoming_or_current = where("ends_on >= ?", today).order(:starts_on)
    past = where("ends_on < ?", today).order(starts_on: :desc)
    # Combine using to_a since AR union would reorder; we want custom ordering
    upcoming_or_current.to_a + past.to_a
  end

  def current_or_upcoming?
    Date.current <= ends_on
  end

  def price
    (price_cents || 0) / 100.0
  end

  def price=(euros)
    self.price_cents = (euros.to_f * 100).round
  end
end
