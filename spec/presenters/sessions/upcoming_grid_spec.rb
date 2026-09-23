# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::UpcomingGrid do
  let(:coach) { create(:user, :coach) }
  let(:level) { create(:level) }
  let(:player) { create(:user, level: level) }
  let(:day) { 3.days.from_now.change(hour: 10) }
  let(:grid) { described_class.new(user: player, sessions: Session.all) }

  def free_play(start_at, **attrs)
    create(:session, :jeu_libre, user: coach, start_at: start_at, end_at: start_at + 90.minutes, **attrs)
  end

  before { create(:credit_transaction, user: player, amount: 1000) }

  it "lists the sessions the player can join, in the given order" do
    later = free_play(day + 4.hours)
    sooner = free_play(day)

    expect(described_class.new(user: player, sessions: Session.order(:start_at)).eligible).to eq([ sooner, later ])
  end

  it "keeps the sessions the player is registered to apart" do
    session = free_play(day)
    registration = create(:registration, user: player, session: session, status: :confirmed)

    expect(grid.registered).to eq([ session ])
    expect(grid.eligible).to be_empty
    expect(grid.registrations_by_session_id).to eq({ session.id => registration })
    expect(grid.confirmed_counts_by_session_id).to eq({ session.id => 1 })
  end

  it "leaves out private coachings and full sessions" do
    create(:session, :coaching_prive, user: coach, start_at: day, end_at: day + 1.hour)
    full = free_play(day + 2.hours, max_players: 1)
    create(:registration, user: create(:user), session: full, status: :confirmed)

    expect(grid.eligible).to be_empty
  end

  it "leaves out the sessions the player cannot afford" do
    free_play(day)

    expect(described_class.new(user: create(:user), sessions: Session.all).eligible).to be_empty
  end

  it "leaves out trainings reserved to other levels" do
    create(:session, user: coach, start_at: day, end_at: day + 90.minutes, levels: [ create(:level) ])
    own_level = create(:session, user: coach, start_at: day + 4.hours, end_at: day + 330.minutes, levels: [ level ])

    expect(grid.eligible).to eq([ own_level ])
    expect(grid.user_level_ids).to eq([ level.id ])
  end

  it "flags the sessions overlapping one the player is confirmed to, that one included" do
    booked = free_play(day)
    overlapping = free_play(day + 30.minutes, terrain: "Terrain 2")
    create(:registration, user: player, session: booked, status: :confirmed)

    expect(grid.conflict_session_ids).to contain_exactly(booked.id, overlapping.id)
  end

  it "exposes the player's balance" do
    expect(grid.balance_amount).to eq(1000)
  end
end
