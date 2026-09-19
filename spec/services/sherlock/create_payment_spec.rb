# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sherlock::CreatePayment do
  let(:user) { create(:user, email: "test@example.com", first_name: "John", last_name: "Doe") }
  let(:credit_purchase) { create(:credit_purchase, user: user, amount_cents: 10_000) }
  let(:gateway) { instance_double(Sherlock::RealGateway, create_payment: :payment_request) }
  let(:service) { described_class.new(credit_purchase, gateway: gateway) }

  def call_with_env(**env)
    with_env({ "APP_HOST" => "https://example.com", "SHERLOCK_RETURN_URL_SUCCESS" => nil }.merge(env)) do
      service.call
    end
  end

  describe '#call' do
    it 'renvoie la requête de paiement construite par la passerelle' do
      expect(call_with_env).to eq(:payment_request)
    end

    it 'transmet le montant et la devise de l’achat' do
      call_with_env

      expect(gateway).to have_received(:create_payment)
        .with(hash_including(amount_cents: 10_000, currency: "EUR"))
    end

    it 'transmet l’identité du client' do
      call_with_env

      expect(gateway).to have_received(:create_payment)
        .with(hash_including(customer: { id: user.id, email: "test@example.com", name: "John Doe" }))
    end

    it 'ne transmet pas de nom quand le modèle n’en expose pas' do
      credit_purchase
      allow(user).to receive(:respond_to?).and_call_original
      allow(user).to receive(:respond_to?).with(:full_name).and_return(false)

      call_with_env

      expect(gateway).to have_received(:create_payment)
        .with(hash_including(customer: hash_including(name: nil)))
    end

    describe 'URLs de rappel' do
      # Sherlock's n'a pas d'URL d'annulation : une seule URL de retour, le
      # résultat étant porté par le responseCode.
      it 'annonce une unique URL de retour et le webhook' do
        call_with_env

        expect(gateway).to have_received(:create_payment).with(
          hash_including(
            return_urls: {
              success: "https://example.com/checkout/return",
              auto: "https://example.com/webhooks/sherlock"
            }
          )
        )
      end

      it 'respecte une URL de retour imposée par l’environnement' do
        call_with_env("SHERLOCK_RETURN_URL_SUCCESS" => "https://example.com/checkout/success")

        expect(gateway).to have_received(:create_payment)
          .with(hash_including(return_urls: hash_including(success: "https://example.com/checkout/success")))
      end
    end

    describe 'référence marchande' do
      it 'réutilise la référence déjà attribuée à l’achat' do
        credit_purchase.update!(sherlock_transaction_reference: "EXISTING-REF-123")

        call_with_env

        expect(gateway).to have_received(:create_payment)
          .with(hash_including(reference: "EXISTING-REF-123"))
      end

      # La référence est l'unique clé de rapprochement avec les réponses de
      # LCL : elle doit être persistée avant d'être transmise.
      it 'en génère une et la persiste quand l’achat n’en a pas' do
        credit_purchase.update!(sherlock_transaction_reference: nil)

        expect { call_with_env }
          .to change { credit_purchase.reload.sherlock_transaction_reference }.from(nil)

        expect(gateway).to have_received(:create_payment)
          .with(hash_including(reference: credit_purchase.reload.sherlock_transaction_reference))
      end
    end

    describe 'devise' do
      it 'utilise celle de l’achat' do
        credit_purchase.update!(currency: "usd")

        call_with_env

        expect(gateway).to have_received(:create_payment).with(hash_including(currency: "USD"))
      end

      it 'se rabat sur celle de l’environnement' do
        credit_purchase.update_column(:currency, "")

        call_with_env("CURRENCY" => "EUR")

        expect(gateway).to have_received(:create_payment).with(hash_including(currency: "EUR"))
      end
    end

    it 'construit sa passerelle depuis l’environnement par défaut' do
      with_env("SHERLOCK_GATEWAY" => "fake", "APP_HOST" => "https://example.com") do
        expect(described_class.new(credit_purchase).call).to be_a(Sherlock::PaymentRequest)
      end
    end
  end
end
