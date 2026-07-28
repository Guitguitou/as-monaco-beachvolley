require 'rails_helper'

RSpec.describe Annonces::ConfirmationService do
  let(:creator) { create(:user) }
  let(:start_at) { (Time.current + 2.days).change(hour: 19, min: 0) }
  let(:annonce) { create(:annonce, user: creator, min_players: 2, slots: [ build(:annonce_slot, start_at: start_at, end_at: start_at + 2.hours) ]) }
  let(:slot) { annonce.slots.first }

  def available_player(credits: 10_000)
    user = create(:user)
    create(:credit_transaction, user: user, amount: credits) if credits.positive?
    create(:annonce_availability, annonce_slot: slot, user: user)
    user
  end

  it "crée une session de jeu libre sur le créneau et le terrain choisis" do
    available_player
    available_player

    result = described_class.new(annonce: annonce, slot: slot, terrain: "Terrain 2").call

    session = result.session
    expect(session).to be_persisted
    expect(session.session_type).to eq("jeu_libre")
    expect(session.terrain).to eq("Terrain 2")
    expect(session.start_at).to eq(start_at)
    expect(session.user).to eq(creator)
  end

  it "inscrit et débite les joueurs solvables" do
    p1 = available_player
    p2 = available_player

    result = described_class.new(annonce: annonce, slot: slot, terrain: "Terrain 1").call

    expect(result.registered).to match_array([ p1, p2 ])
    expect(result.session.participants).to match_array([ p1, p2 ])
    expect(p1.reload.balance.amount).to eq(10_000 - Session::FREE_PLAY_PRICE)
  end

  it "ignore les joueurs insolvables sans faire échouer la session" do
    solvent = available_player
    broke = available_player(credits: 0)

    result = described_class.new(annonce: annonce, slot: slot, terrain: "Terrain 1").call

    expect(result.registered).to eq([ solvent ])
    expect(result.skipped).to eq([ broke ])
    expect(result.session.participants).to eq([ solvent ])
  end

  it "passe l'annonce en confirmed et la relie à la session" do
    available_player
    available_player

    result = described_class.new(annonce: annonce, slot: slot, terrain: "Terrain 1").call

    expect(annonce.reload).to be_confirmed
    expect(annonce.session).to eq(result.session)
  end
end
