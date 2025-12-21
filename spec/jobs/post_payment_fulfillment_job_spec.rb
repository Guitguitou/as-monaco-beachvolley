# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PostPaymentFulfillmentJob, type: :job do
  let(:user) { create(:user) }
  let(:credit_purchase) { create(:credit_purchase, :paid, user: user, credits: 1000) }

  before do
    allow(Rails.logger).to receive(:info)
  end

  describe '#perform' do
    it 'finds the credit purchase' do
      expect(CreditPurchase).to receive(:find).with(credit_purchase.id).and_return(credit_purchase)

      described_class.perform_now(credit_purchase.id)
    end

    it 'logs payment fulfillment information' do
      expect(Rails.logger).to receive(:info).with(
        "Payment fulfilled for CreditPurchase ##{credit_purchase.id} - User ##{user.id} received #{credit_purchase.credits} credits"
      )

      described_class.perform_now(credit_purchase.id)
    end

    it 'handles missing credit purchase gracefully' do
      expect {
        described_class.perform_now(999999)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
