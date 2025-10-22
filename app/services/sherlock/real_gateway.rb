module Sherlock
  class RealGateway < Gateway
    # Gateway réelle pour LCL Sherlock en production
    HOSTED_URL = "https://paiement-sherlock.lcl.fr/hosted"

    def create_payment(reference:, amount_cents:, currency:, return_urls:, customer:)
      params = {
        merchantId: ENV.fetch('SHERLOCK_MERCHANT_ID'),
        terminalId: ENV.fetch('SHERLOCK_TERMINAL_ID'),
        orderId: reference,
        amount: amount_cents,
        currency: currency,
        returnUrlSuccess: return_urls[:success],
        returnUrlCancel: return_urls[:cancel],
        customerEmail: customer[:email]
      }

      # Générer la signature HMAC
      signature = generate_signature(params)
      params[:signature] = signature

      "#{HOSTED_URL}?#{params.to_query}"
    end

    private

    def generate_signature(params)
      # Construire la chaîne à signer selon la doc LCL
      # L'ordre des paramètres est important !
      string_to_sign = [
        params[:merchantId],
        params[:terminalId],
        params[:orderId],
        params[:amount],
        params[:currency],
        params[:returnUrlSuccess],
        params[:returnUrlCancel],
        params[:customerEmail]
      ].join('|')

      # HMAC SHA-256
      OpenSSL::HMAC.hexdigest(
        'SHA256',
        ENV.fetch('SHERLOCK_API_KEY'),
        string_to_sign
      )
    end
  end
end

