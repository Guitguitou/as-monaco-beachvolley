# frozen_string_literal: true

module Shop
  # Panier puis commande d'un membre pour une campagne (cf. GLOSSARY.md).
  # Ses lignes se lisent par Shop::OrderLine.of.
  class Order < ApplicationRecord
    enum :status, { cart: "cart", paid: "paid" }, suffix: true

    belongs_to :user
    belongs_to :campaign

    def self.cart_for(user, campaign) = cart_status.find_by(user: user, campaign: campaign)

    def lines = OrderLine.of(self)

    def total_cents = lines.sum("quantity * unit_price_cents")

    def items_count = lines.sum(:quantity)
  end
end
