# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::CalendarEvents do
  let(:coach) { create(:user, :coach) }
  let(:player) { create(:user) }
  let(:day) { 3.days.from_now.change(hour: 19) }
  let(:events) { described_class.new(user: player, sessions: Session.order(:start_at), url_for: ->(s) { "/sessions/#{s.id}" }) }

  def free_play(start_at = day, **attrs)
    create(:session, :jeu_libre, user: coach, start_at: start_at, end_at: start_at + 90.minutes, terrain: "Terrain 2", **attrs)
  end

  def event_for(session)
    events.sessions.find { |event| event[:id] == session.id }
  end

  it "tells the player's status on each session" do
    registered = free_play(day)
    waitlisted = free_play(day + 2.hours)
    open = free_play(day + 4.hours)
    create(:registration, user: player, session: registered, status: :confirmed)
    create(:registration, user: player, session: waitlisted, status: :waitlisted)

    expect(event_for(registered)).to include(status: "registered", classNames: [ "status-registered", "has-terrain", "terrain-ink" ])
    expect(event_for(waitlisted)[:status]).to eq("waitlisted")
    expect(event_for(open)[:status]).to eq("open")
  end

  it "marks full sessions as unavailable and exposes the fill" do
    full = free_play(max_players: 1)
    create(:registration, user: create(:user), session: full, status: :confirmed)

    expect(event_for(full)).to include(status: "unavailable", confirmedCount: 1, maxPlayers: 1, terrainShort: "T2", terrainColor: "ink",
                                       statusText: "Complet", statusTone: "full")
  end

  it "marks trainings outside the player's levels as unavailable" do
    training = create(:session, :entrainement, user: coach, start_at: day, end_at: day + 2.hours)
    training.levels << create(:level)

    expect(event_for(training)).to include(status: "unavailable", forMe: false)
  end

  it "lists recent terrain closures as background events" do
    terrain = FactoryHelpers.resolve_terrain("Terrain 3")
    TerrainClosure.create!(terrain: terrain, starts_on: Date.new(2030, 3, 13), ends_on: Date.new(2030, 3, 14), reason: "Travaux")
    TerrainClosure.create!(terrain: FactoryHelpers.resolve_terrain("Terrain 1"), starts_on: Time.zone.today - 1.year, ends_on: Time.zone.today - 11.months, reason: "Ancienne")

    expect(events.closures).to eq([
      { start: "2030-03-13", end: "2030-03-15", display: "background", classNames: [ "terrain-closure" ],
        title: "Terrain 3 fermé · Travaux", terrain: terrain.id }
    ])
  end
end
