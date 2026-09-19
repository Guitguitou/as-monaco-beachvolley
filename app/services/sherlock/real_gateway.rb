# frozen_string_literal: true

module Sherlock
  # Construit la requête de paiement réelle vers Sherlock's (Worldline Sips).
  #
  # Sherlock's n'a pas d'URL d'annulation : accepté, refusé, annulé et expiré
  # reviennent tous sur `normalReturnUrl`, le résultat étant porté par le
  # `responseCode` de la réponse signée.
  class RealGateway < Gateway
    DEFAULT_INIT_URL = "https://sherlocks-payment-webinit.secure.lcl.fr/paymentInit"
    DEFAULT_INTERFACE_VERSION = "HP_3.4"
    DEFAULT_CUSTOMER_LANGUAGE = "fr"

    CURRENCY_CODES = { "EUR" => "978" }.freeze

    def self.currency_code_for(currency)
      CURRENCY_CODES.fetch(currency.to_s.upcase) do
        raise ArgumentError, "Devise non gérée: #{currency}"
      end
    end

    def initialize(seal: Seal.from_env)
      @seal = seal
    end

    def create_payment(reference:, amount_cents:, currency:, return_urls:, customer:)
      data = to_data_string(
        payment_data(reference:, amount_cents:, currency:, return_urls:, customer:)
      )

      PaymentRequest.new(
        url: init_url,
        fields: {
          "Data" => data,
          "InterfaceVersion" => interface_version,
          "Seal" => seal.compute(data)
        }
      )
    end

    private

    attr_reader :seal

    def payment_data(reference:, amount_cents:, currency:, return_urls:, customer:)
      {
        "amount" => amount_cents.to_s,
        "currencyCode" => self.class.currency_code_for(currency),
        "merchantId" => ENV.fetch("SHERLOCK_MERCHANT_ID"),
        "keyVersion" => ENV.fetch("SHERLOCK_KEY_VERSION", "1"),
        "orderChannel" => "INTERNET",
        "paymentPattern" => "ONE_SHOT",
        "normalReturnUrl" => return_urls[:success],
        "automaticResponseUrl" => return_urls[:auto],
        "customerEmail" => customer[:email].to_s,
        # Renvoie le client directement sur notre page de résultat au lieu du
        # ticket Sherlock's, qui impose un clic « Continuer » de plus.
        "bypassReceiptPage" => "true",
        "customerLanguage" => ENV.fetch("SHERLOCK_CUSTOMER_LANGUAGE", DEFAULT_CUSTOMER_LANGUAGE)
      }.merge(reference_field(reference)).merge(optional_data).compact_blank
    end

    # Sherlock's accepte la référence marchande sous deux noms selon le contrat.
    def reference_field(reference)
      if ENV["SHERLOCK_USE_ORDER_ID"] == "true"
        { "orderId" => reference }
      else
        { "transactionReference" => reference }
      end
    end

    # Champs facultatifs, pilotés par variables d'environnement pour pouvoir
    # être activés sans redéployer. `paymentMeanBrandList` est ce qui ouvre
    # Apple Pay et Google Pay (APPLEPAY, GOOGLEPAY) : envoyer une marque non
    # active sur le contrat fait échouer l'init, d'où le pilotage par ENV.
    def optional_data
      {
        "paymentMeanBrandList" => ENV["SHERLOCK_PAYMENT_MEAN_BRAND_LIST"],
        "templateName" => ENV["SHERLOCK_TEMPLATE_NAME"],
        "sealAlgorithm" => seal.declared_algorithm
      }
    end

    def to_data_string(pairs)
      pairs.map { |key, value| "#{key}=#{value}" }.join("|")
    end

    def init_url
      ENV.fetch("SHERLOCK_PAYMENT_INIT_URL", DEFAULT_INIT_URL)
    end

    def interface_version
      ENV.fetch("SHERLOCK_INTERFACE_VERSION", DEFAULT_INTERFACE_VERSION)
    end
  end
end
