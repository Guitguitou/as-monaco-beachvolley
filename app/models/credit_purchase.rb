# frozen_string_literal: true

# CreditPurchase model representing a purchase of credits, licence, or stage pack.
#
# Handles:
# - Payment processing via Sherlock gateway
# - Credit allocation for credits packs
# - Account activation for licence packs
# - Stage registration for stage packs
# - Idempotent payment processing
#
# Conversion: 100 crédits = 1 EUR
class CreditPurchase < ApplicationRecord
  CREDITS_PER_EUR = 100

  belongs_to :user, optional: true
  belongs_to :pack, optional: true

  enum :status, {
    pending: 'pending',
    paid: 'paid',
    failed: 'failed',
    cancelled: 'cancelled'
  }, suffix: true

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :credits, presence: true, numericality: { greater_than: 0 }, if: :credits_pack?

  before_create :generate_reference

  # Processes payment according to pack type (idempotent)
  def credit!
    return if paid_status?

    ActiveRecord::Base.transaction do
      if credits_pack?
        process_credits_purchase
      elsif stage_pack?
        process_stage_purchase
      elsif licence_pack?
        process_licence_purchase
      else
        raise 'Type de pack non reconnu'
      end

      update!(
        status: :paid,
        paid_at: Time.current
      )
    end
  end

  def credits_pack?
    pack&.pack_type_credits?
  end

  def stage_pack?
    pack&.pack_type_stage?
  end

  def licence_pack?
    pack&.pack_type_licence?
  end

  def amount_eur
    amount_cents / 100.0
  end

  def mark_as_failed!(reason: nil)
    update!(
      status: :failed,
      failed_at: Time.current,
      sherlock_fields: sherlock_fields.merge(failure_reason: reason)
    )
  end

  # Pack prédéfini : 10 EUR = 1000 crédits
  def self.create_pack_10_eur(user:)
    create!(
      user:,
      amount_cents: 1000,
      currency: 'EUR',
      credits: 1000,
      status: :pending
    )
  end

  private

  def process_credits_purchase
    raise 'Les packs de crédits nécessitent une connexion utilisateur' if user.nil?

    user.balance || user.create_balance!(amount: 0)

    user.credit_transactions.create!(
      transaction_type: :purchase,
      amount: credits,
      session: nil
    )
  end

  def process_stage_purchase
    user_info = user ? "user #{user.id}" : 'anonymous user'
    Rails.logger.info("Stage pack purchased: #{pack.name} by #{user_info}")
    # TODO: Implémenter la logique d'inscription au stage
  end

  def process_licence_purchase
    if user.present?
      user.activate! unless user.activated?
      Rails.logger.info("Licence pack purchased and user activated: #{user.email}")
    else
      Rails.logger.info('Licence pack purchased by anonymous user - stored in sherlock_fields')
    end
  end

  def generate_reference
    self.sherlock_transaction_reference ||= "CP-#{SecureRandom.hex(8).upcase}"
  end
end
