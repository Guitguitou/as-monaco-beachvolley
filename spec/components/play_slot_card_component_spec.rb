# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlaySlotCardComponent, type: :component do
  let(:organizer) { create(:user, first_name: "Julie") }
  let(:player) { create(:user) }
  let(:annonce) { create(:annonce, :with_slot, user: organizer, title: nil, min_players: 4) }
  let(:slot) { annonce.slots.first }

  it "dit combien il manque de joueurs et qui en est déjà" do
    create(:annonce_availability, annonce_slot: slot, user: organizer)

    render_inline(described_class.new(slot: slot.reload, user: player))

    expect(page).to have_text("Il manque 3 joueurs")
    expect(page).to have_text("Partie de Julie")
    expect(page).to have_button("J'en suis")
    expect(page).to have_text("300 crédits si la partie est confirmée")
  end

  it "affiche le titre choisi par l'organisateur" do
    annonce.update!(title: "Session détente")

    render_inline(described_class.new(slot: slot, user: player))

    expect(page).to have_text("Session détente")
  end

  it "propose de se retirer à un joueur déjà dispo" do
    create(:annonce_availability, annonce_slot: slot, user: player)

    render_inline(described_class.new(slot: slot.reload, user: player))

    expect(page).to have_button("Je n'y suis plus")
  end
end
