# frozen_string_literal: true

require "rails_helper"

RSpec.describe Stats::InactivityRanking do
  let(:timezone) { ActiveSupport::TimeZone["Europe/Paris"] }
  let(:coach) { create(:user, :coach) }
  let(:john) { create(:user, first_name: "John", last_name: "Doe") }
  let(:bob) { create(:user, first_name: "Bob", last_name: "Smith") }
  let(:newcomer) { create(:user, first_name: "Nina", last_name: "New") }
  let(:old_session) { create(:session, :jeu_libre, start_at: 30.days.ago, end_at: 30.days.ago + 90.minutes, user: coach) }
  let(:recent_session) { create(:session, :jeu_libre, start_at: 5.days.ago, end_at: 5.days.ago + 90.minutes, user: coach) }
  let(:user_ids) { [ john.id, bob.id, newcomer.id ] }

  before do
    create(:registration, user: john, session: recent_session, status: :confirmed)
    create(:registration, user: bob, session: old_session, status: :confirmed)
  end

  it "puts the players whose last session is the oldest first" do
    ranking = described_class.new(user_ids: user_ids, timezone: timezone).top

    expect(ranking.map { |entry| [ entry[:user], entry[:name], entry[:days_since] ] }).to eq([ [ bob, "Bob Smith", 30 ], [ john, "John Doe", 5 ] ])
    expect(ranking.first[:last_session_at]).to be_within(1.second).of(old_session.start_at)
  end

  it "puts the players who never played before everyone when asked" do
    ranking = described_class.new(user_ids: user_ids, timezone: timezone, include_never_played: true).top

    expect(ranking.first).to eq({ user: newcomer, last_session_at: nil, days_since: nil, name: "Nina New" })
    expect(ranking.map { |entry| entry[:user] }).to eq([ newcomer, bob, john ])
  end

  it "keeps only the given number of players" do
    expect(described_class.new(user_ids: user_ids, timezone: timezone).top(1).map { |entry| entry[:user] }).to eq([ bob ])
  end

  it "ignores test accounts" do
    tester = create(:user, first_name: "Qa", last_name: "Test")
    create(:registration, user: tester, session: old_session, status: :confirmed)

    ranking = described_class.new(user_ids: [ tester.id ], timezone: timezone, include_never_played: true).top

    expect(ranking).to eq([])
  end

  it "returns nothing without players" do
    expect(described_class.new(user_ids: [], timezone: timezone).top).to eq([])
  end
end
