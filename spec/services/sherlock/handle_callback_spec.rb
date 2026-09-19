# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sherlock::HandleCallback do
  let(:user) { create(:user) }
  let(:pack) { create(:pack, :credits, credits: 1000) }
  let(:credit_purchase) do
    create(:credit_purchase, user: user, pack: pack, credits: 1000, sherlock_transaction_reference: "REF-123")
  end

  before do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
    allow(PostPaymentFulfillmentJob).to receive(:perform_later)
  end

  describe '#call' do
    it 'applique l’issue à l’achat visé' do
      credit_purchase

      expect { described_class.new(reference: "REF-123", responseCode: "00").call }
        .to change { credit_purchase.reload.status }.from("pending").to("paid")
    end

    it 'confirme le traitement' do
      credit_purchase

      expect(described_class.new(reference: "REF-123", responseCode: "00").call).to be(true)
    end

    describe 'extraction de la référence' do
      before { credit_purchase }

      it 'lit la clé "reference" normalisée' do
        expect(described_class.new(reference: "REF-123", responseCode: "00").call).to be(true)
      end

      it 'lit transactionReference' do
        expect(described_class.new(transactionReference: "REF-123", responseCode: "00").call).to be(true)
      end

      it 'lit orderId' do
        expect(described_class.new(orderId: "REF-123", responseCode: "00").call).to be(true)
      end
    end

    context 'quand l’achat est introuvable' do
      it 'renvoie false' do
        expect(described_class.new(reference: "INCONNUE", responseCode: "00").call).to be(false)
      end

      it 'le trace, car cela signale une désynchronisation avec LCL' do
        expect(Rails.logger).to receive(:error).with(/CreditPurchase not found/)

        described_class.new(reference: "INCONNUE", responseCode: "00").call
      end
    end

    context 'quand le traitement échoue' do
      before do
        credit_purchase
        allow(Sherlock::ApplyOutcome).to receive(:call).and_raise(StandardError, "Database error")
      end

      it 'renvoie false plutôt que de laisser remonter l’exception' do
        expect(described_class.new(reference: "REF-123", responseCode: "00").call).to be(false)
      end

      it 'trace l’erreur' do
        expect(Rails.logger).to receive(:error).with(/HandleCallback error/)

        described_class.new(reference: "REF-123", responseCode: "00").call
      end
    end
  end
end
