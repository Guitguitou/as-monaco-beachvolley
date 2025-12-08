# frozen_string_literal: true

# Pack model representing purchasable packs (credits, licence, stage).
#
# Handles:
# - Three pack types: credits, licence, stage
# - Pricing (stored in cents, exposed as euros)
# - Credits calculation for credits packs
# - Display name generation
class Pack < ApplicationRecord
  has_many :credit_purchases, dependent: :nullify
  belongs_to :stage, optional: true

  enum :pack_type, {
    credits: "credits",
    licence: "licence",
    stage: "stage"
  }, prefix: true

  validates :name, presence: true
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :pack_type, presence: true
  validates :credits, presence: true, numericality: { greater_than: 0 }, if: :pack_type_credits?
  validates :stage_id, presence: true, if: :pack_type_stage?

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :created_at) }
  scope :credits_packs, -> { where(pack_type: :credits) }
  scope :stage_packs, -> { where(pack_type: :stage) }
  scope :licence_packs, -> { where(pack_type: :licence) }

  def amount_eur
    amount_cents / 100.0
  end

  def amount_eur=(euros)
    self.amount_cents = (euros.to_f * 100).round
  end

  def display_name
    case pack_type
    when "credits"
      "#{name} - #{credits} crédits (#{amount_eur} €)"
    when "licence"
      "#{name} - Licence (#{amount_eur} €)"
    when "stage"
      stage_name = stage&.title || "Stage"
      "#{name} - #{stage_name} (#{amount_eur} €)"
    else
      "#{name} (#{amount_eur} €)"
    end
  end

  def credits_per_euro
    return 0 unless pack_type_credits? && credits.present? && amount_cents.positive?
    (credits.to_f / amount_eur).round(2)
  end
end
