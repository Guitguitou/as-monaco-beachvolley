# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sherlock::RealGateway do
  let(:seal) { Sherlock::Seal.new(secret: "test_secret") }
  let(:gateway) { described_class.new(seal: seal) }
  let(:return_urls) { { success: "https://example.com/checkout/return", auto: "https://example.com/webhooks/sherlock" } }
  let(:customer) { { id: 1, email: "test@example.com", name: "Test User" } }

  # Les champs postés sont concaténés dans `Data` : on les relit avec le même
  # parseur que les réponses, pour vérifier ce que LCL recevra réellement.
  def payment_data(**overrides)
    request = with_env({ "SHERLOCK_MERCHANT_ID" => "TEST_MERCHANT" }.merge(overrides)) do
      gateway.create_payment(
        reference: "TEST-REF-123",
        amount_cents: 10_000,
        currency: "EUR",
        return_urls: return_urls,
        customer: customer
      )
    end

    [ request, Sherlock::DataParser.parse(request.fields["Data"]) ]
  end

  describe '.currency_code_for' do
    it 'traduit EUR en code ISO numérique' do
      expect(described_class.currency_code_for("EUR")).to eq("978")
      expect(described_class.currency_code_for(:eur)).to eq("978")
    end

    it 'refuse une devise non gérée' do
      expect { described_class.currency_code_for("USD") }
        .to raise_error(ArgumentError, /Devise non gérée/)
    end
  end

  describe '#create_payment' do
    it 'poste vers paymentInit avec les trois champs attendus par Sherlock’s' do
      request, = payment_data

      expect(request.url).to eq(described_class::DEFAULT_INIT_URL)
      expect(request.fields.keys).to contain_exactly("Data", "InterfaceVersion", "Seal")
      expect(request.fields["InterfaceVersion"]).to eq(described_class::DEFAULT_INTERFACE_VERSION)
    end

    it 'scelle le Data qu’il transmet' do
      request, = payment_data

      expect(request.fields["Seal"]).to eq(seal.compute(request.fields["Data"]))
    end

    it 'transmet le montant, la devise et le marchand' do
      _request, data = payment_data

      expect(data).to include(
        "amount" => "10000",
        "currencyCode" => "978",
        "merchantId" => "TEST_MERCHANT",
        "orderChannel" => "INTERNET",
        "paymentPattern" => "ONE_SHOT"
      )
    end

    it 'transmet les deux URLs de rappel et l’email du client' do
      _request, data = payment_data

      expect(data).to include(
        "normalReturnUrl" => return_urls[:success],
        "automaticResponseUrl" => return_urls[:auto],
        "customerEmail" => "test@example.com"
      )
    end

    # Sans ce champ, Sherlock’s affiche son propre ticket et impose un clic
    # « Continuer » avant de renvoyer le client sur le site.
    it 'désactive la page de ticket Sherlock’s' do
      _request, data = payment_data

      expect(data["bypassReceiptPage"]).to eq("true")
    end

    it 'demande la page de paiement en français' do
      _request, data = payment_data

      expect(data["customerLanguage"]).to eq("fr")
    end

    it 'permet de changer la langue par variable d’environnement' do
      _request, data = payment_data("SHERLOCK_CUSTOMER_LANGUAGE" => "en")

      expect(data["customerLanguage"]).to eq("en")
    end

    it 'envoie la référence en transactionReference par défaut' do
      _request, data = payment_data("SHERLOCK_USE_ORDER_ID" => nil)

      expect(data["transactionReference"]).to eq("TEST-REF-123")
      expect(data).not_to have_key("orderId")
    end

    it 'envoie la référence en orderId quand le contrat l’exige' do
      _request, data = payment_data("SHERLOCK_USE_ORDER_ID" => "true")

      expect(data["orderId"]).to eq("TEST-REF-123")
      expect(data).not_to have_key("transactionReference")
    end

    it 'reprend la version de clé du contrat' do
      _request, data = payment_data("SHERLOCK_KEY_VERSION" => "3")

      expect(data["keyVersion"]).to eq("3")
    end

    it 'poste sur l’URL d’init configurée' do
      request, = payment_data("SHERLOCK_PAYMENT_INIT_URL" => "https://recette.example.com/paymentInit")

      expect(request.url).to eq("https://recette.example.com/paymentInit")
    end

    describe 'champs facultatifs' do
      it 'n’envoie ni marques ni template quand rien n’est configuré' do
        _request, data = payment_data(
          "SHERLOCK_PAYMENT_MEAN_BRAND_LIST" => nil,
          "SHERLOCK_TEMPLATE_NAME" => nil
        )

        expect(data).not_to have_key("paymentMeanBrandList")
        expect(data).not_to have_key("templateName")
      end

      # C'est ce champ qui ouvre Apple Pay et Google Pay, une fois les options
      # actives sur le contrat Sherlock's.
      it 'transmet la liste des moyens de paiement quand elle est configurée' do
        _request, data = payment_data(
          "SHERLOCK_PAYMENT_MEAN_BRAND_LIST" => "CB,VISA,MASTERCARD,APPLEPAY,GOOGLEPAY"
        )

        expect(data["paymentMeanBrandList"]).to eq("CB,VISA,MASTERCARD,APPLEPAY,GOOGLEPAY")
      end

      it 'transmet la feuille de style de la page de paiement' do
        _request, data = payment_data("SHERLOCK_TEMPLATE_NAME" => "asmbv")

        expect(data["templateName"]).to eq("asmbv")
      end

      it 'n’annonce pas l’algorithme historique, qui est celui par défaut' do
        _request, data = payment_data

        expect(data).not_to have_key("sealAlgorithm")
      end

      it 'annonce l’algorithme HMAC quand il est utilisé' do
        hmac_seal = Sherlock::Seal.new(secret: "test_secret", algorithm: Sherlock::Seal::HMAC_ALGORITHM)
        gateway = described_class.new(seal: hmac_seal)

        request = with_env("SHERLOCK_MERCHANT_ID" => "TEST_MERCHANT") do
          gateway.create_payment(
            reference: "TEST-REF-123", amount_cents: 10_000, currency: "EUR",
            return_urls: return_urls, customer: customer
          )
        end
        data = Sherlock::DataParser.parse(request.fields["Data"])

        expect(data["sealAlgorithm"]).to eq(Sherlock::Seal::HMAC_ALGORITHM)
        expect(request.fields["Seal"]).to eq(hmac_seal.compute(request.fields["Data"]))
      end
    end
  end
end
