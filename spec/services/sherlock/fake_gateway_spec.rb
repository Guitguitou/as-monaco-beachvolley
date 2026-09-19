# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sherlock::FakeGateway do
  let(:seal) { Sherlock::Seal.new(secret: "test_secret") }
  let(:gateway) { described_class.new(seal: seal) }
  let(:return_urls) { { success: "https://example.com/checkout/return", auto: "https://example.com/webhooks/sherlock" } }

  def fake_payment(response_code: nil)
    request = with_env("SHERLOCK_FAKE_RESPONSE_CODE" => response_code) do
      gateway.create_payment(
        reference: "TEST-REF-123",
        amount_cents: 10_000,
        currency: "EUR",
        return_urls: return_urls,
        customer: { id: 1, email: "test@example.com", name: "Test User" }
      )
    end

    [ request, Sherlock::DataParser.parse(request.fields["Data"]) ]
  end

  describe '#create_payment' do
    it 'poste directement sur l’URL de retour' do
      request, = fake_payment

      expect(request.url).to eq(return_urls[:success])
    end

    # Le but est que le flux de retour soit exercé à l'identique en local,
    # vérification du sceau comprise.
    it 'scelle sa réponse comme le ferait Sherlock’s' do
      request, = fake_payment

      expect(request.fields["Seal"]).to eq(seal.compute(request.fields["Data"]))
    end

    it 'simule un paiement accepté par défaut' do
      _request, data = fake_payment

      expect(data["responseCode"]).to eq(Sherlock::Outcome::ACCEPTED_CODE)
    end

    it 'permet de rejouer un refus sans toucher au code' do
      _request, data = fake_payment(response_code: "05")

      expect(data["responseCode"]).to eq("05")
    end

    it 'renvoie la référence, le montant et la devise de l’achat' do
      _request, data = fake_payment

      expect(data).to include(
        "transactionReference" => "TEST-REF-123",
        "amount" => "10000",
        "currencyCode" => "978",
        "customerEmail" => "test@example.com"
      )
    end
  end
end
