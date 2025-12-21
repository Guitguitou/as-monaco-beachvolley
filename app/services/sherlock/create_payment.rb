# frozen_string_literal: true

# app/services/sherlock/create_payment.rb
module Sherlock
  class CreatePayment
    attr_reader :credit_purchase

    def initialize(credit_purchase)
      @credit_purchase = credit_purchase
    end

    # Retourne une STRING de HTML (form POST auto-submit) en "real",
    # et un HTML de redirection immédiate en "fake".
    def call
      gateway = Gateway.build

      # Référence unique côté marchand (si absente, on la génère)
      reference = credit_purchase.sherlock_transaction_reference.presence ||
                  "CP-#{credit_purchase.id}-#{SecureRandom.hex(4)}"

      # On persiste la référence si on vient de la créer
      credit_purchase.update!(sherlock_transaction_reference: reference) if credit_purchase.sherlock_transaction_reference.blank?

      currency = (credit_purchase.currency.presence || ENV.fetch("CURRENCY", "EUR")).upcase

      gateway.create_payment(
        reference: reference,
        amount_cents: credit_purchase.amount_cents,
        currency: currency,
        return_urls: {
          success: success_url,
          cancel:  cancel_url,
          auto:    auto_url
        },
        customer: {
          id:    credit_purchase.user_id,
          email: credit_purchase.user.email,
          name:  (credit_purchase.user.respond_to?(:full_name) ? credit_purchase.user.full_name : nil)
        }
      )
    end

    private

    def success_url
      ENV.fetch("SHERLOCK_RETURN_URL_SUCCESS", "#{app_host}/checkout/success")
    end

    def cancel_url
      ENV.fetch("SHERLOCK_RETURN_URL_CANCEL", "#{app_host}/checkout/cancel")
    end

    # Webhook serveur→serveur (automatique)
    def auto_url
      # Si tu exposes déjà /webhooks/sherlock en POST :
      "#{app_host}/webhooks/sherlock"
    end

    def app_host
      ENV.fetch("APP_HOST", "http://localhost:3000")
    end
  end
end
