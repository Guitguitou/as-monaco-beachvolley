require "rails_helper"

RSpec.describe Admin::AlertsTabComponent, type: :component do
  let(:coach) { create(:user, :coach) }
  let(:session_record) { create(:session, user: coach, max_players: 10, title: "Session Alerte") }
  let(:alerts) do
    {
      late_cancellations: [],
      capacity_alerts: [session_record],
      low_attendance: [],
      upcoming_sessions: []
    }
  end
  let(:alert_counts) do
    {
      late_cancellations: 0,
      capacity_alerts: 1,
      low_attendance: 0,
      upcoming_sessions: 0
    }
  end

  before do
    confirmed_relation = instance_double("ActiveRecord::Relation", count: 9)
    registrations_assoc = instance_double("RegistrationAssociation", confirmed: confirmed_relation)
    allow(session_record).to receive(:registrations).and_return(registrations_assoc)
  end

  it "renders alert cards and capacity details" do
    render_inline(described_class.new(alerts: alerts, alert_counts: alert_counts))

    expect(page).to have_text("Alertes de capacité")
    expect(page).to have_text("Session Alerte")
    expect(page).to have_text("Presque plein")
    expect(page).to have_text("9/10")
  end
end
