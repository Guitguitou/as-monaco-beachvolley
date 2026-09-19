# frozen_string_literal: true

module Sherlock
  # Prépare la requête de paiement d'un achat : référence marchande stable,
  # devise, et les deux URLs que Sherlock's rappellera.
  class CreatePayment
    attr_reader :credit_purchase

    def initialize(credit_purchase, gateway: Gateway.build)
      @credit_purchase = credit_purchase
      @gateway = gateway
    end

    def call
      gateway.create_payment(
        reference: reference,
        amount_cents: credit_purchase.amount_cents,
        currency: currency,
        return_urls: { success: normal_return_url, auto: automatic_response_url },
        customer: customer
      )
    end

    private

    attr_reader :gateway

    # La référence est l'unique clé de rapprochement entre nos achats et les
    # réponses de LCL : on la fige au premier appel et on la réutilise ensuite.
    def reference
      return credit_purchase.sherlock_transaction_reference if credit_purchase.sherlock_transaction_reference.present?

      generated = "CP-#{credit_purchase.id}-#{SecureRandom.hex(4)}"
      credit_purchase.update!(sherlock_transaction_reference: generated)
      generated
    end

    def currency
      (credit_purchase.currency.presence || ENV.fetch("CURRENCY", "EUR")).upcase
    end

    def customer
      user = credit_purchase.user

      {
        id: credit_purchase.user_id,
        email: user.email,
        name: (user.full_name if user.respond_to?(:full_name))
      }
    end

    # Retour du client dans son navigateur, en POST cross-site.
    def normal_return_url
      ENV.fetch("SHERLOCK_RETURN_URL_SUCCESS", "#{app_host}/checkout/return")
    end

    # Notification serveur à serveur, qui ne passe pas par le navigateur.
    def automatic_response_url
      "#{app_host}/webhooks/sherlock"
    end

    def app_host
      ENV.fetch("APP_HOST", "http://localhost:3000")
    end
  end
end
