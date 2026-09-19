# frozen_string_literal: true

module Sherlock
  # Passerelle de développement : poste sur l'URL de retour une réponse signée
  # avec le même sceau que la vraie passerelle. Le flux de retour est donc
  # exercé à l'identique en local, sceau compris.
  #
  # `SHERLOCK_FAKE_RESPONSE_CODE` permet de rejouer un refus (05), une
  # annulation client (17) ou une session expirée (97) sans toucher au code.
  class FakeGateway < Gateway
    def initialize(seal: Seal.from_env)
      @seal = seal
    end

    def create_payment(reference:, amount_cents:, currency:, return_urls:, customer:)
      data = [
        "responseCode=#{ENV.fetch('SHERLOCK_FAKE_RESPONSE_CODE', Outcome::ACCEPTED_CODE)}",
        "transactionReference=#{reference}",
        "amount=#{amount_cents}",
        "currencyCode=#{RealGateway.currency_code_for(currency)}",
        "customerEmail=#{customer[:email]}"
      ].join("|")

      PaymentRequest.new(
        url: return_urls[:success],
        fields: {
          "Data" => data,
          "InterfaceVersion" => RealGateway::DEFAULT_INTERFACE_VERSION,
          "Seal" => seal.compute(data)
        }
      )
    end

    private

    attr_reader :seal
  end
end
