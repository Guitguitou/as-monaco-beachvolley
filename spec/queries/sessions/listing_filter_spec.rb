# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::ListingFilter do
  let(:coach) { create(:user, :coach) }
  let(:level) { create(:level) }
  let(:day) { 3.days.from_now.change(hour: 10) }
  let!(:free_play_t1) { create(:session, :jeu_libre, user: coach, start_at: day, end_at: day + 1.hour) }
  let!(:free_play_t2) { create(:session, :jeu_libre, :terrain_2, user: coach, start_at: day, end_at: day + 1.hour) }
  let!(:other_level_training) { create(:session, user: coach, start_at: day + 3.hours, end_at: day + 4.hours, levels: [ create(:level) ]) }

  it "keeps everything without filter" do
    filter = described_class.new(terrain: nil, for_me: false, level_ids: [ level.id ])

    expect(filter.apply(Session.all)).to contain_exactly(free_play_t1, free_play_t2, other_level_training)
  end

  it "keeps one terrain" do
    filter = described_class.new(terrain: "Terrain 2", for_me: false, level_ids: [])

    expect(filter.apply(Session.all)).to eq([ free_play_t2 ])
  end

  it "keeps the sessions open to the player's levels" do
    filter = described_class.new(terrain: "", for_me: true, level_ids: [ level.id ])

    expect(filter.apply(Session.all)).to contain_exactly(free_play_t1, free_play_t2)
  end
end
