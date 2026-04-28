require "rails_helper"

RSpec.describe Credits::RecordTransaction do
  describe ".call" do
    let(:user) { create(:user) }

    it "creates transaction and updates balance explicitly" do
      expect {
        described_class.call(user: user, transaction_type: :purchase, amount: 300, session: nil)
      }.to change(CreditTransaction, :count).by(1)
       .and change { user.reload.balance.amount }.by(300)
    end
  end
end
