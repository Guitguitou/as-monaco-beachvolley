# frozen_string_literal: true

class CreditPurchase < ApplicationRecord
  belongs_to :user
  belongs_to :pack, optional: true

  # Statuts possibles
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

  # Conversion: 100 crédits = 1 EUR
  CREDITS_PER_EUR = 100

  # Traite le paiement selon le type de pack (idempotent)
  def credit!
    CreditPurchases::ProcessPayment.call(purchase: self)
  end

  # Détermine si c'est un pack de crédits
  def credits_pack?
    pack&.pack_type_credits?
  end

  # Détermine si c'est un pack de stage
  def stage_pack?
    pack&.pack_type_stage?
  end

  # Détermine si c'est un pack de licence
  def licence_pack?
    pack&.pack_type_licence?
  end

  def inscription_tournoi_pack?
    pack&.pack_type_inscription_tournoi?
  end

  def equipements_pack?
    pack&.pack_type_equipements?
  end

  # Calculer le montant en euros
  def amount_eur
    amount_cents / 100.0
  end

  # Marquer comme échoué (méthode publique pour les webhooks)
  def mark_as_failed!(reason: nil)
    update!(
      status: :failed,
      failed_at: Time.current,
      sherlock_fields: sherlock_fields.merge(failure_reason: reason)
    )
  end

  private

  # Générer une référence unique
  def generate_reference
    self.sherlock_transaction_reference ||= "CP-#{SecureRandom.hex(8).upcase}"
  end

  # Pack prédéfini : 10 EUR = 1000 crédits
  def self.create_pack_10_eur(user:)
    create!(
      user:,
      amount_cents: 1000, # 10 EUR
      currency: 'EUR',
      credits: 1000, # 10 EUR * 100 crédits/EUR
      status: :pending
    )
  end
end
