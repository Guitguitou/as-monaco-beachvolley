# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sherlock::RealGateway do
  let(:gateway) { described_class.new }
  let(:reference) { "TEST-REF-123" }
  let(:amount_cents) { 10000 }
  let(:currency) { "EUR" }
  let(:return_urls) do
    {
      success: "https://example.com/success",
      cancel: "https://example.com/cancel",
      auto: "https://example.com/webhook"
    }
  end
  let(:customer) do
    {
      id: 1,
      email: "test@example.com",
      name: "Test User"
    }
  end

  before do
    allow(ENV).to receive(:fetch).with("SHERLOCK_PAYMENT_INIT_URL", anything).and_return("https://test.sherlock.com/init")
    allow(ENV).to receive(:fetch).with("SHERLOCK_INTERFACE_VERSION", anything).and_return("HP_3.4")
    allow(ENV).to receive(:fetch).with("SHERLOCK_KEY_VERSION", anything).and_return("1")
    allow(ENV).to receive(:fetch).with("SHERLOCK_SEAL_ALGO", anything).and_return("sha256")
    allow(ENV).to receive(:fetch).with("SHERLOCK_MERCHANT_ID", anything).and_return("TEST_MERCHANT")
    allow(ENV).to receive(:fetch).with("SHERLOCK_API_KEY", anything).and_return("test_secret_key")
    allow(ENV).to receive(:[]).with("SHERLOCK_USE_ORDER_ID").and_return(nil)
  end

  describe '.currency_code_for' do
    it 'returns 978 for EUR' do
      expect(described_class.currency_code_for("EUR")).to eq("978")
      expect(described_class.currency_code_for(:eur)).to eq("978")
    end

    it 'raises ArgumentError for unsupported currency' do
      expect {
        described_class.currency_code_for("USD")
      }.to raise_error(ArgumentError, /Devise non gérée/)
    end
  end

  describe '#create_payment' do
    it 'returns HTML form with auto-submit' do
      result = gateway.create_payment(
        reference: reference,
        amount_cents: amount_cents,
        currency: currency,
        return_urls: return_urls,
        customer: customer
      )

      expect(result).to include("<html>")
      expect(result).to include("<form")
      expect(result).to include("sherlock_pay")
      expect(result).to include("post")
    end

    it 'includes Data field in form' do
      result = gateway.create_payment(
        reference: reference,
        amount_cents: amount_cents,
        currency: currency,
        return_urls: return_urls,
        customer: customer
      )

      expect(result).to include('name="Data"')
    end

    it 'includes InterfaceVersion field' do
      result = gateway.create_payment(
        reference: reference,
        amount_cents: amount_cents,
        currency: currency,
        return_urls: return_urls,
        customer: customer
      )

      expect(result).to include('name="InterfaceVersion"')
      expect(result).to include("HP_3.4")
    end

    it 'includes Seal field' do
      result = gateway.create_payment(
        reference: reference,
        amount_cents: amount_cents,
        currency: currency,
        return_urls: return_urls,
        customer: customer
      )

      expect(result).to include('name="Seal"')
    end

    it 'includes transactionReference when USE_ORDER_ID is not set' do
      allow(ENV).to receive(:[]).with("SHERLOCK_USE_ORDER_ID").and_return(nil)
      
      result = gateway.create_payment(
        reference: reference,
        amount_cents: amount_cents,
        currency: currency,
        return_urls: return_urls,
        customer: customer
      )

      expect(result).to include(reference)
    end

    it 'includes orderId when USE_ORDER_ID is true' do
      allow(ENV).to receive(:[]).with("SHERLOCK_USE_ORDER_ID").and_return("true")
      
      result = gateway.create_payment(
        reference: reference,
        amount_cents: amount_cents,
        currency: currency,
        return_urls: return_urls,
        customer: customer
      )

      expect(result).to include(reference)
    end

    it 'includes customer email in data' do
      result = gateway.create_payment(
        reference: reference,
        amount_cents: amount_cents,
        currency: currency,
        return_urls: return_urls,
        customer: customer
      )

      expect(result).to include(customer[:email])
    end

    it 'includes return URLs in data' do
      result = gateway.create_payment(
        reference: reference,
        amount_cents: amount_cents,
        currency: currency,
        return_urls: return_urls,
        customer: customer
      )

      expect(result).to include(return_urls[:success])
      expect(result).to include(return_urls[:auto])
    end

    it 'computes seal using sha256 algorithm' do
      result = gateway.create_payment(
        reference: reference,
        amount_cents: amount_cents,
        currency: currency,
        return_urls: return_urls,
        customer: customer
      )

      # The seal should be present in the HTML
      expect(result).to match(/name="Seal" value="[^"]+"/)
    end

    context 'with HMAC-SHA-256 algorithm' do
      before do
        allow(ENV).to receive(:fetch).with("SHERLOCK_SEAL_ALGO", anything).and_return("HMAC-SHA-256")
      end

      it 'computes seal using HMAC-SHA-256' do
        result = gateway.create_payment(
          reference: reference,
          amount_cents: amount_cents,
          currency: currency,
          return_urls: return_urls,
          customer: customer
        )

        expect(result).to match(/name="Seal" value="[^"]+"/)
      end
    end
  end
end

