# frozen_string_literal: true

module CreditPurchases
  module Processors
    # Commande d'équipements : le paiement accepté la passe en payée.
    class ShopOrder
      def initialize(purchase:)
        @purchase = purchase
      end

      def call
        @purchase.shop_order.mark_paid!
      end
    end
  end
end
