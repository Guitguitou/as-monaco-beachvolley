require "rails_helper"

RSpec.describe Admin::SessionsTabComponent, type: :component do
  let(:coach) { create(:user, :coach, first_name: "Nora", last_name: "Coach") }
  let(:session_record) { create(:session, user: coach, max_players: 10) }
  let(:component) { described_class.new(sessions: [session_record], filters: {}) }

  before do
    confirmed_relation = instance_double("ActiveRecord::Relation", count: 8)
    registrations_assoc = instance_double("RegistrationAssociation", confirmed: confirmed_relation)
    allow(session_record).to receive(:registrations).and_return(registrations_assoc)
  end

  it "returns session types for filter options" do
    types = component.send(:session_types)

    expect(types.map { |t| t[:value] }).to include("", "entrainement", "jeu_libre", "coaching_prive")
  end

  it "classifies capacity as high for 80 percent occupancy" do
    expect(component.send(:capacity_status, session_record)).to eq("high")
    expect(component.send(:capacity_status_text, "high")).to eq("Presque plein")
  end
end
