require "rails_helper"

RSpec.describe Registrations::EligibilityChecker do
  describe ".call" do
    let(:level) { create(:level) }
    let(:user) { create(:user, level: level) }
    let(:session_record) { create(:session, session_type: "entrainement", levels: [level], start_at: Time.current + 2.days, end_at: Time.current + 2.days + 90.minutes) }
    let(:registration) { build(:registration, user: user, session: session_record, status: :confirmed) }

    before do
      create(:credit_transaction, user: user, amount: 10_000)
    end

    it "returns allowed result when all constraints pass" do
      result = described_class.call(registration: registration)

      expect(result.allowed?).to be(true)
      expect(result.code).to be_nil
      expect(result.reason).to be_nil
    end

    it "returns a reason when session is full" do
      session_record.update!(max_players: 0)

      result = described_class.call(registration: registration)
      expect(result.allowed?).to be(false)
      expect(result.code).to eq(:session_full)
      expect(result.reason).to eq("Session complète.")
    end
  end
end
