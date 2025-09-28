class Stage < ApplicationRecord
  # Associations
  belongs_to :main_coach, class_name: 'User', optional: true
  belongs_to :assistant_coach, class_name: 'User', optional: true

  # Attachments
  has_one_attached :image

  # Validations
  validates :title, presence: true
  validates :starts_on, presence: true
  validates :ends_on, presence: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :ends_on_after_starts_on

  # Scopes
  scope :ordered_for_players, -> do
    today = Date.current
    upcoming_or_current = where('ends_on >= ?', today).order(:starts_on)
    past = where('ends_on < ?', today).order(starts_on: :desc)
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

  private

  def ends_on_after_starts_on
    return if starts_on.blank? || ends_on.blank?
    errors.add(:ends_on, 'doit être après la date de début') if ends_on < starts_on
  end
end
