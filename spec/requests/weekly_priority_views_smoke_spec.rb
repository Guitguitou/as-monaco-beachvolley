# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Affichage de la priorité hebdomadaire", type: :request do
  let(:monday) { Time.zone.parse("2035-01-01 10:00:00") } # un lundi
  let(:coach) { create(:user, :coach, activated_at: Time.current) }
  let(:level) { create(:level) }
  let(:player) { create(:user, level: level, activated_at: Time.current) }

  around { |example| travel_to(monday) { example.run } }

  before { create(:credit_transaction, user: player, amount: 10_000) }

  def training(day_offset:, terrain:)
    start_at = (monday + 7.days + day_offset.days).change(hour: 19)
    create(:session, session_type: "entrainement", terrain: terrain, user: coach,
                     levels: [ level ], start_at: start_at, end_at: start_at + 1.hour,
                     max_players: 12, registration_opens_at: monday - 1.day)
  end

  it "signale le 2e entraînement de la semaine sur la fiche session, la grille et Mes sessions" do
    first = training(day_offset: 0, terrain: "Terrain 1")
    second = training(day_offset: 2, terrain: "Terrain 2")
    create(:registration, user: player, session: first, status: :confirmed)

    sign_in player, scope: :user

    get session_path(second)
    expect(response.body).to include("Ce serait ton 2e entraînement de la semaine")

    get sessions_path(view: "grid")
    expect(response.body).to include("2e entraînement")

    get me_sessions_path
    expect(response).to have_http_status(:ok)
  end
end
