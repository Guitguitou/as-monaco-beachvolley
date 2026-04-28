require "rails_helper"

RSpec.describe CreditPurchases::ProcessPayment do
  describe ".call" do
    let(:user) { create(:user) }
    let(:credits_pack) { create(:pack, pack_type: "credits") }

    it "marks purchase as paid and creates credits transaction" do
      purchase = create(:credit_purchase, user: user, pack: credits_pack, credits: 1000, amount_cents: 1000)

      expect {
        described_class.call(purchase: purchase)
      }.to change { user.reload.balance.amount }.by(1000)

      expect(purchase.reload).to be_paid_status
      expect(purchase.paid_at).to be_present
    end
  end
end
