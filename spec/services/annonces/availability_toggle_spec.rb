# frozen_string_literal: true

require "rails_helper"

RSpec.describe Annonces::AvailabilityToggle do
  let(:annonce) { create(:annonce, slots: [ build(:annonce_slot) ]) }
  let(:slot) { annonce.slots.first }
  let(:player) { create(:user) }

  before { allow(SendPushNotificationJob).to receive(:perform_later) }

  it "declares the player available and tells the organiser" do
    described_class.new(annonce: annonce, slot: slot, user: player).call

    expect(AnnonceAvailability.where(annonce_slot: slot, user: player)).to exist
    expect(SendPushNotificationJob).to have_received(:perform_later).with(annonce.user.id, anything)
  end

  it "withdraws an availability already declared, without notifying" do
    create(:annonce_availability, annonce_slot: slot, user: player)

    described_class.new(annonce: annonce, slot: slot, user: player).call

    expect(AnnonceAvailability.where(annonce_slot: slot, user: player)).not_to exist
    expect(SendPushNotificationJob).not_to have_received(:perform_later)
  end
end
