module CreditPurchases
  module Processors
    class Licence
      def initialize(purchase:)
        @purchase = purchase
      end

      def call
        if purchase.user.present?
          purchase.user.activate! unless purchase.user.activated?
          Rails.logger.info("Licence pack purchased and user activated: #{purchase.user.email}")
        else
          Rails.logger.info("Licence pack purchased by anonymous user - stored in sherlock_fields")
        end
      end

      private

      attr_reader :purchase
    end
  end
end
