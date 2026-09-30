# frozen_string_literal: true

require "rails_helper"

RSpec.describe Annonces::OpenSlotsQuery do
  let(:player) { create(:user) }

  def annonce_at(start_at, user: create(:user), min_players: 4)
    create(:annonce, user: user, min_players: min_players,
                     slots: [ build(:annonce_slot, start_at: start_at, end_at: start_at + 2.hours) ])
  end

  it "met en tête les créneaux les plus près d'être complets, puis les plus proches" do
    empty_soon = annonce_at(1.day.from_now).slots.first
    almost_full = annonce_at(3.days.from_now).slots.first
    3.times { create(:annonce_availability, annonce_slot: almost_full) }
    empty_later = annonce_at(2.days.from_now).slots.first

    expect(described_class.call(user: player)).to eq([ almost_full, empty_soon, empty_later ])
  end

  it "inclut les créneaux des parties du joueur lui-même" do
    own = annonce_at(1.day.from_now, user: player).slots.first

    expect(described_class.call(user: player)).to include(own)
  end

  it "ignore les créneaux passés d'une partie encore ouverte" do
    annonce = create(:annonce, user: create(:user), slots: [
      build(:annonce_slot, start_at: 1.day.from_now, end_at: 1.day.from_now + 2.hours),
      build(:annonce_slot, start_at: 2.days.from_now, end_at: 2.days.from_now + 2.hours)
    ])
    past = annonce.slots.min_by(&:start_at)
    past.update_columns(start_at: 1.day.ago, end_at: 1.day.ago + 2.hours)

    expect(described_class.call(user: player)).not_to include(past)
  end

  it "limite le nombre de créneaux" do
    3.times { |i| annonce_at((i + 1).days.from_now) }

    expect(described_class.call(user: player, limit: 2).size).to eq(2)
  end
end
