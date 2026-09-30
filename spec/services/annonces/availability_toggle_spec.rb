# frozen_string_literal: true

require "rails_helper"

RSpec.describe Annonces::AvailabilityToggle do
  let(:annonce) { create(:annonce, min_players: 3, slots: [ build(:annonce_slot) ]) }
  let(:slot) { annonce.slots.first }
  let(:player) { create(:user) }

  before { allow(SendPushNotificationJob).to receive(:perform_later) }

  def toggle(user)
    described_class.new(annonce: annonce, slot: slot.reload, user: user).call
  end

  it "declares the player available and tells the organiser" do
    toggle(player)

    expect(AnnonceAvailability.where(annonce_slot: slot, user: player)).to exist
    expect(SendPushNotificationJob).to have_received(:perform_later).with(annonce.user.id, anything)
  end

  it "withdraws an availability already declared, without notifying" do
    create(:annonce_availability, annonce_slot: slot, user: player)

    toggle(player)

    expect(AnnonceAvailability.where(annonce_slot: slot, user: player)).not_to exist
    expect(SendPushNotificationJob).not_to have_received(:perform_later)
  end

  it "refuse un créneau passé" do
    slot.update_columns(start_at: 1.day.ago, end_at: 1.day.ago + 2.hours)

    expect(toggle(player)).to be(false)
    expect(AnnonceAvailability.where(annonce_slot: slot)).to be_empty
  end

  it "relance les joueurs éligibles une seule fois quand il ne manque plus qu'un joueur" do
    candidate = create(:user)
    toggle(create(:user))
    toggle(player)
    toggle(player) # se retire…
    toggle(player) # …et revient : pas de seconde relance

    expect(SendPushNotificationJob).to have_received(:perform_later)
      .with(candidate.id, hash_including(title: "Plus qu'un joueur et ça joue 🏐")).once
    expect(slot.reload.last_call_sent_at).to be_present
  end

  it "invite le créateur à confirmer quand le quota est atteint" do
    2.times { toggle(create(:user)) }
    toggle(player)

    expect(SendPushNotificationJob).to have_received(:perform_later)
      .with(annonce.user.id, hash_including(title: "Ta partie est prête 🎉")).once
  end
end
