module CreditPurchases
  module Processors
    class Credits
      def initialize(purchase:)
        @purchase = purchase
      end

      def call
        raise "Les packs de crédits nécessitent une connexion utilisateur" if purchase.user.nil?

        purchase.user.balance || purchase.user.create_balance!(amount: 0)
        CreditTransaction.record!(
          user: purchase.user,
          transaction_type: :purchase,
          amount: purchase.credits,
          session: nil
        )
      end

      private

      attr_reader :purchase
    end
  end
end
