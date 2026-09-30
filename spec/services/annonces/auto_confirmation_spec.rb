# frozen_string_literal: true

require "rails_helper"

RSpec.describe Annonces::AutoConfirmation do
  let(:creator) { create(:user) }

  before { allow(SendPushNotificationJob).to receive(:perform_later) }

  def annonce_starting_in(delay, players:)
    start_at = Time.current + delay
    annonce = create(:annonce, user: creator, min_players: 2,
                               slots: [ build(:annonce_slot, start_at: start_at, end_at: start_at + 2.hours) ])
    players.times do
      user = create(:user)
      create(:credit_transaction, user: user, amount: 10_000)
      create(:annonce_availability, annonce_slot: annonce.slots.first, user: user)
    end
    annonce
  end

  it "confirme une partie prête qui commence dans moins de 24 h" do
    annonce = annonce_starting_in(10.hours, players: 2)

    expect { described_class.call }.to change(Session, :count).by(1)

    expect(annonce.reload).to be_confirmed
    expect(SendPushNotificationJob).to have_received(:perform_later).with(creator.id, hash_including(title: "Jeu libre confirmé 🎉"))
  end

  it "laisse au créateur le temps de confirmer quand la partie est plus lointaine" do
    annonce_starting_in(3.days, players: 2)

    expect { described_class.call }.not_to change(Session, :count)
  end

  it "ne confirme pas une partie qui n'a pas atteint le quota" do
    annonce = annonce_starting_in(10.hours, players: 1)

    described_class.call

    expect(annonce.reload).to be_open
  end

  it "ne confirme pas quand aucun terrain n'est libre" do
    annonce = annonce_starting_in(10.hours, players: 2)
    slot = annonce.slots.first
    Session.terrains.each_key do |terrain|
      create(:session, :jeu_libre, terrain: terrain, start_at: slot.start_at, end_at: slot.end_at)
    end

    described_class.call

    expect(annonce.reload).to be_open
  end
end
