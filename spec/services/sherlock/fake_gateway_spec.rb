# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sherlock::FakeGateway do
  describe '#create_payment' do
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

    it 'returns HTML with redirect script' do
      result = gateway.create_payment(
        reference: reference,
        amount_cents: amount_cents,
        currency: currency,
        return_urls: return_urls,
        customer: customer
      )

      expect(result).to include("<html>")
      expect(result).to include("FakeGateway")
      expect(result).to include("window.location")
      expect(result).to include(return_urls[:success])
    end

    it 'includes transaction reference in redirect URL' do
      result = gateway.create_payment(
        reference: reference,
        amount_cents: amount_cents,
        currency: currency,
        return_urls: return_urls,
        customer: customer
      )

      expect(result).to include(reference)
    end

    it 'includes success response code in redirect URL' do
      result = gateway.create_payment(
        reference: reference,
        amount_cents: amount_cents,
        currency: currency,
        return_urls: return_urls,
        customer: customer
      )

      expect(result).to include("responseCode=00")
      expect(result).to include("transactionStatus=ACCEPTED")
    end
  end
end

