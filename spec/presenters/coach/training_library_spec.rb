# frozen_string_literal: true

require "rails_helper"

RSpec.describe Coach::TrainingLibrary do
  let(:coach) { create(:user, :coach) }
  let(:other_coach) { create(:user, :coach) }
  let(:level_a) { create(:level) }
  let(:level_b) { create(:level) }
  let(:day) { 3.days.from_now.change(hour: 10) }

  def training(offset, coach:, levels: [], notes: "Travail du service")
    create(:session, user: coach, levels: levels, coach_notes: notes, start_at: day + offset, end_at: day + offset + 1.hour)
  end

  it "files each noted training under every one of its levels, latest first" do
    older = training(0, coach: coach, levels: [ level_a ])
    both = training(2.hours, coach: other_coach, levels: [ level_a, level_b ])
    open = training(4.hours, coach: coach)
    training(6.hours, coach: coach, notes: "")

    library = described_class.new(user: coach, only_mine: false)

    expect(library.by_level_id).to eq({ level_a.id => [ both, older ], level_b.id => [ both ], nil => [ open ] })
    expect(library.levels).to eq({ level_a.id => level_a, level_b.id => level_b })
  end

  it "keeps the coach's own trainings when asked" do
    mine = training(0, coach: coach, levels: [ level_a ])
    training(2.hours, coach: other_coach, levels: [ level_a ])

    expect(described_class.new(user: coach, only_mine: true).by_level_id).to eq({ level_a.id => [ mine ] })
  end
end
