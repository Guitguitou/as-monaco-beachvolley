# frozen_string_literal: true

module CreditPurchases
  module Processors
    # Packs qui ne créditent rien (stage, tournoi, équipement) : l'achat est
    # seulement tracé, la suite se gère hors de l'application.
    class LogOnly
      def initialize(purchase:, label:)
        @purchase = purchase
        @label = label
      end

      def call
        Rails.logger.info("#{@label} pack purchased: #{@purchase.pack.name} by user #{@purchase.user_id}")
      end
    end
  end
end
