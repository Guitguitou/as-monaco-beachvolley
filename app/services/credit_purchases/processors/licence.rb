module CreditPurchases
  module Processors
    class Licence
      def initialize(purchase:)
        @purchase = purchase
      end

      def call
        user = purchase.user

        if user.blank?
          Rails.logger.info("Licence pack purchased by anonymous user - stored in sherlock_fields")
        elsif user.activated?
          # Compte déjà actif pour la saison en cours : ce paiement vaut pour la
          # saison suivante. La coche protège le compte lors du reset de saison.
          user.mark_next_season_renewed!
          Rails.logger.info("Licence pack purchased for next season by activated user: #{user.email}")
        else
          user.activate!
          Rails.logger.info("Licence pack purchased and user activated: #{user.email}")
        end
      end

      private

      attr_reader :purchase
    end
  end
end
