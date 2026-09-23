# frozen_string_literal: true

require "rails_helper"

RSpec.describe Stats::SessionCountRanking do
  let(:coach) { create(:user, :coach) }
  let(:john) { create(:user, first_name: "John", last_name: "Doe") }
  let(:bob) { create(:user, first_name: "Bob", last_name: "Smith") }
  let(:free_play) { create(:session, :jeu_libre, start_at: 2.days.ago, end_at: 2.days.ago + 90.minutes, user: coach) }
  let(:other_free_play) { create(:session, :jeu_libre, start_at: 3.days.ago, end_at: 3.days.ago + 90.minutes, user: coach) }

  before do
    create(:registration, user: john, session: free_play, status: :confirmed)
    create(:registration, user: john, session: other_free_play, status: :confirmed)
    create(:registration, user: bob, session: free_play, status: :confirmed)
  end

  describe "#top" do
    it "returns the players with the most valid registrations first" do
      ranking = described_class.new(user_ids: [ john.id, bob.id ])

      expect(ranking.top).to eq([
        { user: john, count: 2, name: "John Doe" },
        { user: bob, count: 1, name: "Bob Smith" }
      ])
    end

    it "keeps only the given number of players" do
      expect(described_class.new(user_ids: [ john.id, bob.id ]).top(1).map { |entry| entry[:user] }).to eq([ john ])
    end

    it "counts only registrations to the given sessions" do
      ranking = described_class.new(user_ids: [ john.id, bob.id ], sessions: Session.where(id: other_free_play.id))

      expect(ranking.top).to eq([ { user: john, count: 1, name: "John Doe" } ])
    end

    it "ignores test accounts and players outside the given ids" do
      tester = create(:user, first_name: "Qa", last_name: "Test")
      create(:registration, user: tester, session: free_play, status: :confirmed)

      expect(described_class.new(user_ids: [ bob.id, tester.id ]).top.map { |entry| entry[:user] }).to eq([ bob ])
    end

    it "returns nothing without players" do
      expect(described_class.new(user_ids: []).top).to eq([])
    end
  end

  describe "#ordered_user_ids" do
    it "gives every ranked player id, best first" do
      expect(described_class.new(user_ids: [ bob.id, john.id ]).ordered_user_ids).to eq([ john.id, bob.id ])
    end
  end

  describe "#full" do
    it "ranks every player" do
      ranking = described_class.new(user_ids: [ john.id, bob.id ])

      expect(ranking.full.map { |entry| [ entry[:rank], entry[:user], entry[:count] ] }).to eq([ [ 1, john, 2 ], [ 2, bob, 1 ] ])
    end
  end
end
