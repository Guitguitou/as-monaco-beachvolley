# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PostPaymentFulfillmentJob, type: :job do
  let(:user) { create(:user) }
  let(:credit_purchase) { create(:credit_purchase, :paid, user: user, credits: 1000) }
  let(:brevo_service) { instance_double(Brevo::TransactionalEmail, send_payment_confirmation: true) }

  before do
    allow(Rails.logger).to receive(:info)
    allow(Brevo::TransactionalEmail).to receive(:new).and_return(brevo_service)
  end

  describe '#perform' do
    context 'when the credit purchase exists' do
      it 'sends the Brevo payment confirmation and logs the fulfillment' do
        expect(CreditPurchase).to receive(:find).with(credit_purchase.id).and_return(credit_purchase)
        expect(brevo_service).to receive(:send_payment_confirmation).with(credit_purchase)
        expect(Rails.logger).to receive(:info).with(
          "Payment fulfilled for CreditPurchase ##{credit_purchase.id} - User ##{user.id} received #{credit_purchase.credits} credits"
        )

        described_class.perform_now(credit_purchase.id)
      end
    end

    context 'when the credit purchase is missing' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          described_class.perform_now(999_999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
