module CreditPurchases
  module Processors
    class InscriptionTournoi
      def initialize(purchase:)
        @purchase = purchase
      end

      def call
        user_info = purchase.user ? "user #{purchase.user.id}" : "anonymous user"
        Rails.logger.info("Inscription tournoi pack purchased: #{purchase.pack.name} by #{user_info}")
      end

      private

      attr_reader :purchase
    end
  end
end
