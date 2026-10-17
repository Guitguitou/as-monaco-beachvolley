# frozen_string_literal: true

require "rails_helper"

RSpec.describe Annonces::SlotCandidatesQuery do
  let(:level) { create(:level, name: "G1") }
  let(:creator) { create(:user) }
  let(:start_at) { 2.days.from_now.change(hour: 19) }
  let(:annonce) { create(:annonce, user: creator, slots: [ build(:annonce_slot, start_at: start_at, end_at: start_at + 2.hours) ]) }
  let(:slot) { annonce.slots.first }

  it "retient les joueurs activés, hors créateur et hors joueurs déjà dispos" do
    free = create(:user)
    already_in = create(:user)
    create(:annonce_availability, annonce_slot: slot, user: already_in)
    not_activated = create(:user, activated_at: nil)

    result = described_class.call(slot: slot)

    expect(result).to include(free)
    expect(result).not_to include(creator, already_in, not_activated)
  end

  it "écarte les joueurs déjà inscrits à une session qui chevauche le créneau" do
    busy = create(:user)
    create(:credit_transaction, user: busy, amount: 10_000)
    create(:registration, user: busy, session: create(:session, :jeu_libre, start_at: start_at, end_at: start_at + 2.hours))

    expect(described_class.call(slot: slot)).not_to include(busy)
  end

  it "ne garde que les niveaux ciblés par la partie" do
    annonce.update!(levels: [ level ])
    matching = create(:user, level: level)
    other = create(:user, level: create(:level, name: "G2"))

    result = described_class.call(slot: slot)

    expect(result).to include(matching)
    expect(result).not_to include(other)
  end
end
