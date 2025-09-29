class CreditPackage < ApplicationRecord
  has_many :payments, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :credits, presence: true, numericality: { greater_than: 0 }
  validates :price_cents, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:price_cents) }

  def price
    price_cents / 100.0
  end

  def price=(euros)
    self.price_cents = (euros.to_f * 100).round
  end

  def display_name
    "#{name} - #{credits} crédits (#{price}€)"
  end
end
