# app/services/sherlock/real_gateway.rb
module Sherlock
  class RealGateway < Gateway
    # URL paymentInit (prod par défaut, surchargable via ENV)
    INIT_URL = ENV.fetch("SHERLOCK_PAYMENT_INIT_URL", "https://sherlocks-payment-webinit.secure.lcl.fr/paymentInit")

    # Version d’interface Paypage (doc Sherlock)
    INTERFACE_VERSION = ENV.fetch("SHERLOCK_INTERFACE_VERSION", "HP_2.18")

    # keyVersion fournie par LCL (souvent "1")
    KEY_VERSION = ENV.fetch("SHERLOCK_KEY_VERSION", "1")

    # currencyCode ISO num (EUR = 978)
    def self.currency_code_for(currency)
      case currency.to_s.upcase
      when "EUR" then "978"
      else
        raise ArgumentError, "Devise non gérée: #{currency}"
      end
    end

    # Retourne un fragment HTML <form method=POST ...> auto-submit
    # A RENDRE tel quel dans le contrôleur (render html: html.html_safe, layout: false)
    def create_payment(reference:, amount_cents:, currency:, return_urls:, customer:)
      data_pairs = ordered_data_pairs(
        reference: reference,
        amount_cents: amount_cents,
        currency: currency,
        return_urls: return_urls,
        customer: customer
      )

      data_string = to_data_string(data_pairs)                       # "k=v|k=v|..."
      seal        = hmac_sha256(ENV.fetch("SHERLOCK_API_KEY"), data_string)

      <<~HTML
        <form id="sips" method="post" action="#{INIT_URL}">
          <input type="hidden" name="Data" value="#{ERB::Util.html_escape(data_string)}">
          <input type="hidden" name="InterfaceVersion" value="#{INTERFACE_VERSION}">
          <input type="hidden" name="Seal" value="#{seal}">
          <input type="hidden" name="SealAlgorithm" value="HMAC-SHA-256">
        </form>
        <script>document.getElementById('sips').submit()</script>
      HTML
    end

    private

    # IMPORTANT : garder un ordre stable des champs dans Data (pratique pour déboguer et éviter les surprises)
    def ordered_data_pairs(reference:, amount_cents:, currency:, return_urls:, customer:)
      {
        "amount"               => amount_cents.to_s,                                    # 10€ => "1000"
        "currencyCode"         => self.class.currency_code_for(currency),               # "978"
        "merchantId"           => ENV.fetch("SHERLOCK_MERCHANT_ID"),
        "keyVersion"           => KEY_VERSION,
        # Retour manuel (navigateur de l’acheteur)
        "normalReturnUrl"      => return_urls[:success],                                # ex: https://.../checkout/success
        # Retour automatique serveur→serveur (webhook) — INDISPENSABLE
        "automaticResponseUrl" => return_urls[:auto] || "#{ENV.fetch("APP_HOST")}/webhooks/sherlock",
        # Identifiant transaction côté marchand (unique)
        "transactionReference" => reference,                                            # ex: "CP-7AE73E09..."
        # Infos client (optionnelles mais utiles)
        "customerEmail"        => customer[:email].to_s
      }
    end

    def to_data_string(pairs_hash)
      # Construit "k=v|k=v|k=v" exactement dans l'ordre fourni
      pairs_hash.map { |k, v| "#{k}=#{v}" }.join("|")
    end

    def hmac_sha256(secret, data)
      OpenSSL::HMAC.hexdigest("SHA256", secret, data)
    end
  end
end
