# frozen_string_literal: true

module Sherlock
  # Point d'entrée du webhook serveur à serveur : retrouve l'achat visé, puis
  # laisse ApplyOutcome décider — exactement comme le retour navigateur.
  #
  # Le webhook reste le filet de sécurité du flux : le client peut fermer son
  # onglet avant de revenir sur le site, auquel cas c'est la seule notification
  # que l'on recevra.
  class HandleCallback
    def initialize(params)
      @params = params.to_h.with_indifferent_access
    end

    def call
      unless purchase
        Rails.logger.error("[Sherlock] CreditPurchase not found for reference: #{reference}")
        return false
      end

      outcome = ApplyOutcome.call(purchase: purchase, fields: params)
      Rails.logger.info("[Sherlock] #{reference} -> #{outcome}")
      true
    rescue StandardError => e
      Rails.logger.error("[Sherlock] HandleCallback error: #{e.class} - #{e.message}")
      false
    end

    private

    attr_reader :params

    def reference
      @reference ||= params[:reference].presence ||
                     params[:transactionReference].presence ||
                     params[:orderId].presence
    end

    def purchase
      @purchase ||= CreditPurchase.find_by(sherlock_transaction_reference: reference)
    end
  end
end
