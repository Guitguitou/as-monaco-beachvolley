require "rails_helper"

RSpec.describe CreditPurchases::Processors::Licence do
  let(:licence_pack) { create(:pack, :licence) }

  describe "#call" do
    it "activates a non-activated user" do
      user = create(:user, activated_at: nil)
      purchase = create(:credit_purchase, user: user, pack: licence_pack)

      described_class.new(purchase: purchase).call

      expect(user.reload.activated?).to be(true)
      expect(user.next_season_renewed?).to be(false)
    end

    it "flags the next season for an already activated user without touching activated_at" do
      activated_at = 2.months.ago
      user = create(:user, activated_at: activated_at)
      purchase = create(:credit_purchase, user: user, pack: licence_pack)

      described_class.new(purchase: purchase).call

      expect(user.reload.next_season_renewed?).to be(true)
      expect(user.activated_at).to be_within(1.second).of(activated_at)
    end

    it "does nothing for an anonymous purchase" do
      purchase = build(:credit_purchase, pack: licence_pack)
      purchase.user = nil

      expect { described_class.new(purchase: purchase).call }.not_to raise_error
    end
  end
end
