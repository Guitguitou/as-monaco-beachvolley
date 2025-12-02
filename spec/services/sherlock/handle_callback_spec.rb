# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sherlock::HandleCallback do
  let(:user) { create(:user) }
  let(:credit_purchase) { create(:credit_purchase, user: user, sherlock_transaction_reference: "REF-123") }
  let(:params) { { reference: "REF-123", status: "paid" } }
  let(:service) { described_class.new(params) }

  before do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:warn)
    allow(Rails.logger).to receive(:error)
    allow(PostPaymentFulfillmentJob).to receive(:perform_later)
  end

  describe '#call' do
    context 'when credit purchase is found' do
      before do
        credit_purchase
      end

      context 'with paid status' do
        let(:params) { { reference: "REF-123", status: "paid" } }
        let(:pack) { create(:pack, pack_type: :credits, credits: 1000) }

        before do
          credit_purchase.update!(pack: pack)
        end

        it 'credits the user and marks purchase as paid' do
          expect {
            service.call
          }.to change { credit_purchase.reload.status }.to("paid")
          
          expect(credit_purchase.paid_at).to be_present
        end

        it 'does not credit if already paid' do
          credit_purchase.update!(status: :paid, paid_at: Time.current)
          
          expect {
            service.call
          }.not_to change { credit_purchase.reload.status }
        end

        it 'stores callback data in sherlock_fields' do
          expect {
            service.call
          }.to change { credit_purchase.reload.sherlock_fields }
          
          expect(credit_purchase.sherlock_fields["callback"]).to be_present
          expect(credit_purchase.sherlock_fields["received_at"]).to be_present
        end
      end

      context 'with failed status' do
        it 'marks purchase as failed with error message' do
          service = described_class.new({ reference: "REF-123", status: "failed", errorMessage: "Insufficient funds" })
          
          service.call
          credit_purchase.reload
          
          expect(credit_purchase.status).to eq("failed")
          expect(credit_purchase.failed_at).to be_present
          expect(credit_purchase.sherlock_fields["failure_reason"]).to eq("Insufficient funds")
        end

        it 'uses responseMessage if errorMessage is missing' do
          service = described_class.new({ reference: "REF-123", status: "failed", responseMessage: "Card declined" })
          
          service.call
          credit_purchase.reload
          
          expect(credit_purchase.status).to eq("failed")
          expect(credit_purchase.sherlock_fields["failure_reason"]).to eq("Card declined")
        end

        it 'uses default message if no error message provided' do
          service = described_class.new({ reference: "REF-123", status: "failed" })
          
          service.call
          credit_purchase.reload
          
          expect(credit_purchase.status).to eq("failed")
          expect(credit_purchase.sherlock_fields["failure_reason"]).to eq("Unknown error")
        end
      end

      context 'with cancelled status' do
        let(:params) { { reference: "REF-123", status: "cancelled" } }

        it 'updates status to cancelled' do
          expect {
            service.call
          }.to change { credit_purchase.reload.status }.to("cancelled")
        end
      end

      context 'with unknown status' do
        let(:params) { { reference: "REF-123", status: "unknown" } }

        it 'logs a warning and does not change status' do
          expect(Rails.logger).to receive(:warn).with(/Unknown status/)
          
          expect {
            service.call
          }.not_to change { credit_purchase.reload.status }
        end
      end
    end

    context 'when credit purchase is not found' do
      let(:params) { { reference: "NONEXISTENT-REF", status: "paid" } }

      it 'returns false' do
        expect(service.call).to eq(false)
      end

      it 'logs an error' do
        expect(Rails.logger).to receive(:error).with(/CreditPurchase not found/)
        service.call
      end
    end

    describe 'reference extraction' do
      let(:pack) { create(:pack, pack_type: :credits, credits: 1000) }

      before do
        credit_purchase.update!(pack: pack)
      end

      it 'extracts reference from :reference key' do
        params = { reference: "REF-123", status: "paid" }
        service = described_class.new(params)
        
        expect(service.call).to eq(true)
      end

      it 'extracts reference from :orderId key' do
        params = { orderId: "REF-123", status: "paid" }
        service = described_class.new(params)
        
        expect(service.call).to eq(true)
      end

      it 'extracts reference from :transactionReference key' do
        params = { transactionReference: "REF-123", status: "paid" }
        service = described_class.new(params)
        
        expect(service.call).to eq(true)
      end
    end

    describe 'status normalization' do
      let(:pack) { create(:pack, pack_type: :credits, credits: 1000) }

      before do
        credit_purchase.update!(pack: pack)
      end

      it 'normalizes "success" to "paid"' do
        params = { reference: "REF-123", status: "success" }
        service = described_class.new(params)
        
        expect {
          service.call
        }.to change { credit_purchase.reload.status }.to("paid")
      end

      it 'normalizes "authorized" to "paid"' do
        params = { reference: "REF-123", status: "authorized" }
        service = described_class.new(params)
        
        expect {
          service.call
        }.to change { credit_purchase.reload.status }.to("paid")
      end

      it 'normalizes "00" to "paid"' do
        params = { reference: "REF-123", responseCode: "00" }
        service = described_class.new(params)
        
        expect {
          service.call
        }.to change { credit_purchase.reload.status }.to("paid")
      end

      it 'normalizes "refused" to "failed"' do
        service = described_class.new({ reference: "REF-123", status: "refused" })
        
        service.call
        
        expect(credit_purchase.reload.status).to eq("failed")
      end

      it 'normalizes "97" to "failed"' do
        service = described_class.new({ reference: "REF-123", responseCode: "97" })
        
        service.call
        
        expect(credit_purchase.reload.status).to eq("failed")
      end

      it 'normalizes "cancelled" to "cancelled"' do
        params = { reference: "REF-123", status: "cancelled" }
        service = described_class.new(params)
        
        expect {
          service.call
        }.to change { credit_purchase.reload.status }.to("cancelled")
      end

      it 'normalizes blank status to "failed"' do
        service = described_class.new({ reference: "REF-123", status: "" })
        
        service.call
        
        expect(credit_purchase.reload.status).to eq("failed")
      end
    end

    context 'when an error occurs' do
      before do
        allow(credit_purchase).to receive(:update!).and_raise(StandardError.new("Database error"))
      end

      it 'returns false' do
        expect(service.call).to eq(false)
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/HandleCallback error/)
        service.call
      end
    end
  end
end

