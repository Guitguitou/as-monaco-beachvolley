# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sherlock::CreatePayment do
  let(:user) { create(:user, email: "test@example.com") }
  let(:credit_purchase) { create(:credit_purchase, user: user, amount_cents: 10000) }
  let(:service) { described_class.new(credit_purchase) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("CURRENCY", anything).and_return("EUR")
    allow(ENV).to receive(:fetch).with("SHERLOCK_RETURN_URL_SUCCESS", anything).and_return("https://example.com/success")
    allow(ENV).to receive(:fetch).with("SHERLOCK_RETURN_URL_CANCEL", anything).and_return("https://example.com/cancel")
    allow(ENV).to receive(:fetch).with("APP_HOST", anything).and_return("https://example.com")
    allow(Sherlock::Gateway).to receive(:build).and_return(double(create_payment: "<html>payment form</html>"))
  end

  describe '#call' do
    it 'calls gateway create_payment with correct parameters' do
      gateway = double
      allow(Sherlock::Gateway).to receive(:build).and_return(gateway)

      expect(gateway).to receive(:create_payment).with(
        reference: credit_purchase.sherlock_transaction_reference || match(/CP-#{credit_purchase.id}-/),
        amount_cents: credit_purchase.amount_cents,
        currency: "EUR",
        return_urls: hash_including(
          success: "https://example.com/success",
          cancel: "https://example.com/cancel",
          auto: "https://example.com/webhooks/sherlock"
        ),
        customer: hash_including(
          id: user.id,
          email: user.email
        )
      )

      service.call
    end

    it 'uses existing transaction reference if present' do
      credit_purchase.update!(sherlock_transaction_reference: "EXISTING-REF-123")

      gateway = double
      allow(Sherlock::Gateway).to receive(:build).and_return(gateway)

      expect(gateway).to receive(:create_payment).with(
        hash_including(reference: "EXISTING-REF-123")
      )

      service.call
    end

    it 'generates and saves transaction reference if missing' do
      credit_purchase.update!(sherlock_transaction_reference: nil)

      expect {
        service.call
      }.to change { credit_purchase.reload.sherlock_transaction_reference }.from(nil)

      expect(credit_purchase.sherlock_transaction_reference).to match(/CP-#{credit_purchase.id}-/)
    end

    it 'uses currency from credit_purchase if present' do
      credit_purchase.update!(currency: "USD")

      gateway = double
      allow(Sherlock::Gateway).to receive(:build).and_return(gateway)

      expect(gateway).to receive(:create_payment).with(
        hash_including(currency: "USD")
      )

      service.call
    end

    it 'defaults to EUR currency if not set' do
      credit_purchase.update_column(:currency, "")

      gateway = double
      allow(Sherlock::Gateway).to receive(:build).and_return(gateway)

      expect(gateway).to receive(:create_payment).with(
        hash_including(currency: "EUR")
      )

      service.call
    end

    it 'includes user full_name in customer if available' do
      user.update!(first_name: "John", last_name: "Doe")

      gateway = double
      allow(Sherlock::Gateway).to receive(:build).and_return(gateway)

      expect(gateway).to receive(:create_payment).with(
        hash_including(
          customer: hash_including(
            name: "John Doe"
          )
        )
      )

      service.call
    end

    it 'handles user without full_name method' do
      allow(user).to receive(:respond_to?).with(:full_name).and_return(false)

      gateway = double
      allow(Sherlock::Gateway).to receive(:build).and_return(gateway)

      expect(gateway).to receive(:create_payment).with(
        hash_including(
          customer: hash_including(
            name: nil
          )
        )
      )

      service.call
    end

    it 'returns the HTML from gateway' do
      gateway = double(create_payment: "<html>payment form</html>")
      allow(Sherlock::Gateway).to receive(:build).and_return(gateway)

      result = service.call
      expect(result).to eq("<html>payment form</html>")
    end
  end
end
