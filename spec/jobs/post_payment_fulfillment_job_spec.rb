# frozen_string_literal: true

require "rails_helper"

RSpec.describe PostPaymentFulfillmentJob, type: :job do
  let(:user) { create(:user) }
  let(:credit_purchase) { create(:credit_purchase, :paid, user: user, credits: 1000) }
  let(:mail_double) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

  before do
    allow(Rails.logger).to receive(:info)
    allow(PaymentMailer).to receive(:payment_accepted).with(credit_purchase).and_return(mail_double)
  end

  describe "#perform" do
    context "when the credit purchase exists" do
      it "sends the payment accepted email and logs the fulfillment" do
        expect(CreditPurchase).to receive(:find).with(credit_purchase.id).and_return(credit_purchase)
        expect(PaymentMailer).to receive(:payment_accepted).with(credit_purchase).and_return(mail_double)
        expect(mail_double).to receive(:deliver_later)
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
