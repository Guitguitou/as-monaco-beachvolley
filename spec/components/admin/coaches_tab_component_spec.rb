require "rails_helper"

RSpec.describe Admin::CoachesTabComponent, type: :component do
  let(:coach) { create(:user, :coach, first_name: "Leo", last_name: "Martin") }
  let(:session_record) { create(:session, user: coach, title: "Session Coach", max_players: 12) }
  let(:coach_breakdown) do
    [
      {
        user: coach,
        week_count: 2,
        month_count: 4,
        year_count: 10,
        week_amount: 120.0,
        month_amount: 240.0,
        year_amount: 1200.0
      }
    ]
  end
  let(:upcoming_sessions_by_coach) { { coach.id => [session_record] } }

  before do
    confirmed_relation = instance_double("ActiveRecord::Relation", count: 3)
    registrations_assoc = instance_double("RegistrationAssociation", confirmed: confirmed_relation)
    allow(session_record).to receive(:registrations).and_return(registrations_assoc)
  end

  it "renders coach recap and upcoming sessions section" do
    render_inline(described_class.new(coach_breakdown: coach_breakdown, upcoming_sessions_by_coach: upcoming_sessions_by_coach))

    expect(page).to have_text("Récapitulatif par coach")
    expect(page).to have_text("Leo Martin")
    expect(page).to have_text("Session Coach")
    expect(page).to have_text("3/12")
  end
end
