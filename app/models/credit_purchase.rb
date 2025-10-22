class CreditPurchase < ApplicationRecord
  belongs_to :user
  belongs_to :pack, optional: true

  # Statuts possibles
  enum :status, {
    pending: "pending",
    paid: "paid",
    failed: "failed",
    cancelled: "cancelled"
  }, suffix: true

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :credits, presence: true, numericality: { greater_than: 0 }

  before_create :generate_reference

  # Conversion: 100 crédits = 1 EUR
  CREDITS_PER_EUR = 100

  # Crédite le compte de l'utilisateur (idempotent)
  def credit!
    return if paid_status? # Déjà traité, ne rien faire

    ActiveRecord::Base.transaction do
      # Créer ou trouver le balance de l'utilisateur
      balance = user.balance || user.create_balance!(amount: 0)

      # Créer la transaction de crédit
      credit_transaction = user.credit_transactions.create!(
        transaction_type: :purchase,
        amount: credits,
        session: nil
      )

      # Incrémenter le solde de l'utilisateur
      balance.increment!(:amount, credits)

      # Marquer comme payé
      update!(
        status: :paid,
        paid_at: Time.current
      )
    end
  end

  # Marquer comme échoué
  def mark_as_failed!(reason: nil)
    update!(
      status: :failed,
      failed_at: Time.current,
      sherlock_fields: sherlock_fields.merge(failure_reason: reason)
    )
  end

  # Générer une référence unique
  def generate_reference
    self.sherlock_transaction_reference ||= "CP-#{SecureRandom.hex(8).upcase}"
  end

  # Calculer le montant en euros
  def amount_eur
    amount_cents / 100.0
  end

  # Pack prédéfini : 10 EUR = 1000 crédits
  def self.create_pack_10_eur(user:)
    create!(
      user: user,
      amount_cents: 1000, # 10 EUR
      currency: 'EUR',
      credits: 1000, # 10 EUR * 100 crédits/EUR
      status: :pending
    )
  end
end
