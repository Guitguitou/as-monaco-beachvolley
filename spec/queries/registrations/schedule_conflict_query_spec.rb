require "rails_helper"

RSpec.describe Registrations::ScheduleConflictQuery do
  describe ".call" do
    let(:level) { create(:level) }
    let(:user) { create(:user, level: level) }
    let(:base_start) { (Time.current + 2.days).change(hour: 18) }

    before do
      create(:credit_transaction, user: user, amount: 10_000)
    end

    it "returns overlapping confirmed sessions for the user" do
      overlapping_session = create(:session, session_type: "entrainement", start_at: base_start, end_at: base_start + 90.minutes, levels: [level], terrain: "Terrain 1")
      target_session = create(:session, session_type: "entrainement", start_at: base_start + 10.minutes, end_at: base_start + 100.minutes, levels: [level], terrain: "Terrain 2")

      create(:registration, user: user, session: overlapping_session, status: :confirmed)

      result = described_class.call(user: user, session: target_session)
      expect(result).to include(overlapping_session)
    end
  end
end
