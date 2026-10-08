# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tournaments::Save do
  let(:admin) { create(:user, :admin) }

  def save(tournament)
    described_class.new(tournament: tournament, owner: admin).call
  end

  it "crée un pack tournoi fermé au prix par équipe" do
    tournament = build(:tournament)

    expect(save(tournament)).to be(true)
    expect(tournament.pack).to have_attributes(pack_type: "inscription_tournoi", amount_cents: 3000, active: false, name: "Tournoi mixte")
  end

  it "occupe chaque terrain coché, chaque jour, aux horaires du tournoi" do
    tournament = build(:tournament, ends_on: Date.current + 3.weeks + 1.day, terrain_names: [ "Terrain 1", "Terrain 2" ])

    save(tournament)

    sessions = tournament.sessions.order(:start_at, :terrain)
    expect(sessions.size).to eq(4)
    expect(sessions.map(&:session_type).uniq).to eq([ "tournoi" ])
    expect(sessions.first.start_at.strftime("%H:%M")).to eq("10:00")
    expect(sessions.first.end_at.strftime("%H:%M")).to eq("16:00")
  end

  it "fait suivre les sessions quand le tournoi change" do
    tournament = build(:tournament, terrain_names: [ "Terrain 1", "Terrain 2", "Terrain 3" ])
    save(tournament)

    tournament.assign_attributes(terrain_names: [ "Terrain 1" ], start_time: "09:00")
    save(tournament)

    expect(tournament.sessions.pluck(:terrain)).to eq([ "Terrain 1" ])
    expect(tournament.sessions.first.start_at.strftime("%H:%M")).to eq("09:00")
  end

  it "conserve l'ouverture du paiement décidée par l'admin" do
    tournament = build(:tournament)
    save(tournament)
    tournament.pack.update!(active: true)

    tournament.price = 40
    save(tournament)

    expect(tournament.pack.reload).to have_attributes(active: true, amount_cents: 4000)
  end

  it "n'enregistre rien si un terrain est déjà pris" do
    day = Date.current + 3.weeks
    create(:session, terrain: "Terrain 1", start_at: day.in_time_zone.change(hour: 12), end_at: day.in_time_zone.change(hour: 13), user: admin)
    tournament = build(:tournament, terrain_names: [ "Terrain 1" ])

    expect(save(tournament)).to be(false)
    expect(tournament.errors[:base].join).to include("Terrain 1")
    expect(Tournament.count).to eq(0)
    expect(Pack.where(pack_type: "inscription_tournoi").count).to eq(0)
  end
end
