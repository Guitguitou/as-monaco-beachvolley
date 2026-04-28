module CreditPurchases
  module Processors
    class Equipements
      def initialize(purchase:)
        @purchase = purchase
      end

      def call
        user_info = purchase.user ? "user #{purchase.user.id}" : "anonymous user"
        Rails.logger.info("Equipements pack purchased: #{purchase.pack.name} by #{user_info}")
      end

      private

      attr_reader :purchase
    end
  end
end
