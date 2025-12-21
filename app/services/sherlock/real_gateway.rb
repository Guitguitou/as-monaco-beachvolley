# frozen_string_literal: true

# app/services/sherlock/real_gateway.rb
require "openssl"
require "erb"

module Sherlock
  class RealGateway < Gateway
    INIT_URL          = ENV.fetch("SHERLOCK_PAYMENT_INIT_URL", "https://sherlocks-payment-webinit.secure.lcl.fr/paymentInit")
    INTERFACE_VERSION = ENV.fetch("SHERLOCK_INTERFACE_VERSION", "HP_3.4")  # ⬅️ HP_3.4
    KEY_VERSION       = ENV.fetch("SHERLOCK_KEY_VERSION", "1")
    SEAL_ALGO         = ENV.fetch("SHERLOCK_SEAL_ALGO", "sha256")          # "sha256" || "HMAC-SHA-256"
    USE_ORDER_ID      = ENV["SHERLOCK_USE_ORDER_ID"] == "true"             # true -> envoie orderId, false -> transactionReference

    def self.currency_code_for(currency)
      case currency.to_s.upcase
      when "EUR" then "978"
      else raise ArgumentError, "Devise non gérée: #{currency}"
      end
    end

    # Retourne un HTML <form> auto-submit vers paymentInit
    def create_payment(reference:, amount_cents:, currency:, return_urls:, customer:)
      data_pairs = ordered_data_pairs(reference:, amount_cents:, currency:, return_urls:, customer:)
      data_string = to_data_string(data_pairs)

      secret = ENV.fetch("SHERLOCK_API_KEY")
      seal   = compute_seal(SEAL_ALGO, data_string, secret)

      <<~HTML
        <!doctype html>
        <html>
          <head><meta charset="utf-8"><title>Redirection paiement</title></head>
          <body>
            <form id="sherlock_pay" method="post" action="#{ERB::Util.html_escape(INIT_URL)}">
              <input type="hidden" name="Data" value="#{ERB::Util.html_escape(data_string)}">
              <input type="hidden" name="InterfaceVersion" value="#{ERB::Util.html_escape(INTERFACE_VERSION)}">
              <input type="hidden" name="Seal" value="#{ERB::Util.html_escape(seal)}">
            </form>
            <script>document.getElementById('sherlock_pay').submit()</script>
          </body>
        </html>
      HTML
    end

    private

    def ordered_data_pairs(reference:, amount_cents:, currency:, return_urls:, customer:)
      base = {
        "amount"               => amount_cents.to_s,
        "currencyCode"         => self.class.currency_code_for(currency),
        "merchantId"           => ENV.fetch("SHERLOCK_MERCHANT_ID"),
        "keyVersion"           => KEY_VERSION,
        "orderChannel"         => "INTERNET",        # recommandé / parfois requis
        "paymentPattern"       => "ONE_SHOT",        # recommandé / parfois requis
        "normalReturnUrl"      => return_urls[:success],
        "automaticResponseUrl" => return_urls[:auto] || "#{ENV.fetch('APP_HOST')}/webhooks/sherlock",
        "customerEmail"        => customer[:email].to_s
      }

      if USE_ORDER_ID
        base["orderId"] = reference
      else
        base["transactionReference"] = reference
      end

      base
    end

    def to_data_string(pairs_hash)
      pairs_hash.map { |k, v| "#{k}=#{v}" }.join("|")
    end

    # Supporte les deux modes:
    # - "HMAC-SHA-256": HMAC(Data, secret)
    # - "sha256": SHA256(Data + secret)  (conforme à leur exemple mail/script)
    def compute_seal(seal_algo, data, secret)
      case seal_algo
      when "HMAC-SHA-256"
        OpenSSL::HMAC.hexdigest("SHA256", secret, data)
      else # "sha256" (Data + secret) par défaut
        Digest::SHA256.hexdigest(data + secret)
      end
    end
  end
end
