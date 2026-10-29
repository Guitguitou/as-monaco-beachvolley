# frozen_string_literal: true

module Shop
  # Panier puis commande d'un membre pour une campagne (cf. GLOSSARY.md).
  # Ses lignes se lisent par Shop::OrderLine.of. Pendant le paiement, le
  # panier est verrouillé : le montant payé est celui des lignes figées.
  class Order < ApplicationRecord
    enum :status, { cart: "cart", awaiting_payment: "awaiting_payment", paid: "paid" }, suffix: true

    belongs_to :user
    belongs_to :campaign

    def self.cart_for(user, campaign) = cart_status.find_by(user: user, campaign: campaign)

    def self.awaiting_payment_for(user, campaign) = awaiting_payment_status.find_by(user: user, campaign: campaign)

    # Le paiement accepté passe la commande en payée et lui donne son numéro.
    def mark_paid!(at: Time.current)
      update!(status: :paid, paid_at: at, number: format("CMD-%<year>d-%<id>04d", year: at.year, id: id))
    end

    def lines = OrderLine.of(self)

    def total_cents = lines.sum("quantity * unit_price_cents")

    def items_count = lines.sum(:quantity)
  end
end
