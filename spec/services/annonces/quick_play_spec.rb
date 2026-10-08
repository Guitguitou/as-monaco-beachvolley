# frozen_string_literal: true

require "rails_helper"

RSpec.describe Annonces::QuickPlay do
  let(:level) { create(:level, name: "G1") }
  let(:player) { create(:user, level: level) }
  let(:quick_slot) { Annonces::QuickSlot.find("demain_soir") }

  before { allow(SendPushNotificationJob).to receive(:perform_later) }

  it "lance une partie au niveau du joueur, où il est d'office dispo" do
    result = described_class.new(user: player, quick_slot: quick_slot).call

    annonce = result.annonce
    expect(result.joined).to be(false)
    expect(annonce.user).to eq(player)
    expect(annonce.levels).to eq([ level ])
    expect(annonce.title).to start_with("Jeu libre ·")
    expect(annonce.slots.first.start_at).to eq(quick_slot.start_at)
    expect(annonce.slots.first.available_users).to eq([ player ])
  end

  it "prévient les joueurs éligibles" do
    other = create(:user, level: level)

    described_class.new(user: player, quick_slot: quick_slot).call

    expect(SendPushNotificationJob).to have_received(:perform_later).with(other.id, anything)
  end

  it "rejoint une partie existante sur le même moment plutôt que d'en créer une" do
    existing = create(:annonce, user: create(:user),
                                slots: [ build(:annonce_slot, start_at: quick_slot.start_at, end_at: quick_slot.end_at) ])

    result = nil
    expect { result = described_class.new(user: player, quick_slot: quick_slot).call }.not_to change(Annonce, :count)

    expect(result.joined).to be(true)
    expect(result.annonce).to eq(existing)
    expect(existing.slots.first.available_users).to include(player)
  end
end
