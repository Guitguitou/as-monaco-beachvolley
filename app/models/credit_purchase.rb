# frozen_string_literal: true

class CreditPurchase < ApplicationRecord
  belongs_to :user, optional: true
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
    return if paid_status? # Déjà traité, ne rien faire

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

      # Marquer comme payé
      update!(
        status: :paid,
        paid_at: Time.current
      )
    end
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

  # Calculer le montant en euros
  def amount_eur
    amount_cents / 100.0
  end

  private

  def process_credits_purchase
    # Les packs de crédits nécessitent un utilisateur connecté
    raise 'Les packs de crédits nécessitent une connexion utilisateur' if user.nil?

    # Créer ou trouver le balance de l'utilisateur
    user.balance || user.create_balance!(amount: 0)

    # Créer la transaction de crédit (le callback apply_amount_delta s'occupe de l'incrémentation)
    user.credit_transactions.create!(
      transaction_type: :purchase,
      amount: credits,
      session: nil
    )
  end

  def process_stage_purchase
    # Pour les stages, on pourrait créer une inscription ou un enregistrement
    # Pour l'instant, on log juste l'achat
    user_info = user ? "user #{user.id}" : 'anonymous user'
    Rails.logger.info("Stage pack purchased: #{pack.name} by #{user_info}")
    # TODO: Implémenter la logique d'inscription au stage
    # Pour les utilisateurs anonymes, on pourrait stocker l'email dans sherlock_fields
  end

  def process_licence_purchase
    # Active le compte utilisateur lors du paiement de la licence
    if user.present?
      user.activate! unless user.activated?
      Rails.logger.info("Licence pack purchased and user activated: #{user.email}")
    else
      # Pour les utilisateurs anonymes, on pourrait stocker l'email dans sherlock_fields
      # et activer le compte ultérieurement quand ils se connectent/créent un compte
      Rails.logger.info('Licence pack purchased by anonymous user - stored in sherlock_fields')
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
