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
  end

  describe '#call' do
    context 'when credit purchase is found' do
      before do
        credit_purchase
      end

      context 'with paid status' do
        let(:params) { { reference: "REF-123", status: "paid" } }

        it 'credits the user and marks purchase as paid' do
          expect(credit_purchase).to receive(:paid_status?).and_return(false)
          expect(credit_purchase).to receive(:credit!)
          expect(PostPaymentFulfillmentJob).to receive(:perform_later).with(credit_purchase.id)
          
          service.call
        end

        it 'does not credit if already paid' do
          credit_purchase.update!(status: :paid, paid_at: Time.current)
          
          expect(credit_purchase).not_to receive(:credit!)
          expect(PostPaymentFulfillmentJob).not_to receive(:perform_later)
          
          service.call
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
        let(:params) { { reference: "REF-123", status: "failed", errorMessage: "Insufficient funds" } }

        it 'marks purchase as failed' do
          expect(credit_purchase).to receive(:mark_as_failed!).with(reason: "Insufficient funds")
          
          service.call
        end

        it 'uses responseMessage if errorMessage is missing' do
          params[:errorMessage] = nil
          params[:responseMessage] = "Card declined"
          
          expect(credit_purchase).to receive(:mark_as_failed!).with(reason: "Card declined")
          
          service.call
        end

        it 'uses default message if no error message provided' do
          params.delete(:errorMessage)
          params.delete(:responseMessage)
          
          expect(credit_purchase).to receive(:mark_as_failed!).with(reason: "Unknown error")
          
          service.call
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
      it 'normalizes "success" to "paid"' do
        params = { reference: "REF-123", status: "success" }
        service = described_class.new(params)
        
        expect(credit_purchase).to receive(:paid_status?).and_return(false)
        expect(credit_purchase).to receive(:credit!)
        
        service.call
      end

      it 'normalizes "authorized" to "paid"' do
        params = { reference: "REF-123", status: "authorized" }
        service = described_class.new(params)
        
        expect(credit_purchase).to receive(:paid_status?).and_return(false)
        expect(credit_purchase).to receive(:credit!)
        
        service.call
      end

      it 'normalizes "00" to "paid"' do
        params = { reference: "REF-123", responseCode: "00" }
        service = described_class.new(params)
        
        expect(credit_purchase).to receive(:paid_status?).and_return(false)
        expect(credit_purchase).to receive(:credit!)
        
        service.call
      end

      it 'normalizes "refused" to "failed"' do
        params = { reference: "REF-123", status: "refused" }
        service = described_class.new(params)
        
        expect(credit_purchase).to receive(:mark_as_failed!)
        
        service.call
      end

      it 'normalizes "97" to "failed"' do
        params = { reference: "REF-123", responseCode: "97" }
        service = described_class.new(params)
        
        expect(credit_purchase).to receive(:mark_as_failed!)
        
        service.call
      end

      it 'normalizes "cancelled" to "cancelled"' do
        params = { reference: "REF-123", status: "cancelled" }
        service = described_class.new(params)
        
        expect {
          service.call
        }.to change { credit_purchase.reload.status }.to("cancelled")
      end

      it 'normalizes blank status to "failed"' do
        params = { reference: "REF-123", status: "" }
        service = described_class.new(params)
        
        expect(credit_purchase).to receive(:mark_as_failed!)
        
        service.call
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

