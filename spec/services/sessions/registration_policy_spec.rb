require "rails_helper"

RSpec.describe Sessions::RegistrationPolicy do
  describe "#open_state" do
    let(:coach) { create(:user, coach: true) }
    let(:user) { create(:user, license_type: "loisir") }
    let(:today) { Time.zone.parse("2026-05-10 10:00:00") }
    let(:session_record) do
      create(
        :session,
        session_type: "entrainement",
        user: coach,
        start_at: today.change(hour: 19),
        end_at: today.change(hour: 20, min: 30),
        registration_opens_at: today.change(hour: 9)
      )
    end

    around do |example|
      travel_to(today) { example.run }
    end

    it "blocks non-competition users during priority window" do
      policy = described_class.new(session: session_record, user: user)

      allowed, reason = policy.open_state
      expect(allowed).to be(false)
      expect(reason).to include("Priorité licence compétition")
    end
  end
end
