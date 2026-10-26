# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::HomeDashboard do
  let(:coach) { create(:user, :coach) }
  let(:dashboard) { described_class.new(routes: Rails.application.routes.url_helpers) }

  it "liste les séances des 7 prochains jours remplies à moins de 40 %, les plus vides d'abord" do
    empty = create(:session, user: coach, start_at: 2.days.from_now, end_at: 2.days.from_now + 1.hour, max_players: 10)
    half = create(:session, user: coach, start_at: 3.days.from_now, end_at: 3.days.from_now + 1.hour, max_players: 10)
    create_list(:registration, 3, session: half, status: :confirmed)
    full = create(:session, user: coach, start_at: 1.day.from_now, end_at: 1.day.from_now + 1.hour, max_players: 2)
    create_list(:registration, 2, session: full, status: :confirmed)

    expect(dashboard.at_risk_sessions.map(&:session)).to eq([ empty, half ])
  end

  it "ouvre chaque action sur le tableau déjà filtré" do
    create(:user, activated_at: 1.day.ago, dossier_complet: false)
    dossiers = dashboard.actions.first

    expect(dossiers.count).to eq(1)
    expect(dossiers.path).to eq("/admin/users?f%5Bactivated%5D=1&f%5Bdossier_complet%5D=0")
  end
end
