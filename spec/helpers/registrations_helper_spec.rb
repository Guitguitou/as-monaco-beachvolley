require "rails_helper"

RSpec.describe RegistrationsHelper, type: :helper do
  let(:coach) { create(:user, :coach) }
  let(:session_record) { create(:session, user: coach, session_type: "entrainement") }

  it "returns a not-open badge before registration opens" do
    travel_to(Time.zone.parse("2026-04-09 10:00")) do
      session_record.update!(registration_opens_at: 1.hour.from_now)
      badge = helper.registration_open_badge(session_record)

      expect(badge).to include("Pas encore ouvert")
    end
  end

  it "returns a priority badge during priority window" do
    travel_to(Time.zone.parse("2026-04-09 10:00")) do
      session_record.update!(registration_opens_at: 1.hour.ago)
      badge = helper.registration_open_badge(session_record)

      expect(badge).to include("Priorité compétition")
    end
  end
end
