# frozen_string_literal: true

require "rails_helper"

RSpec.describe Registration, type: :model do
  describe "#priority_rank" do
    let(:g1) { create(:level, name: "G1", gender: "male") }
    let(:g2) { create(:level, name: "G2", gender: "male") }
    let(:session_record) { create(:session, max_players: 4, price: 400) }
    let(:user) { create(:user) }

    before do
      create(:credit_transaction, user: user, amount: 1000)
      create(:session_level, session: session_record, level: g1, priority: 1)
      create(:session_level, session: session_record, level: g2, priority: 2)
    end

    it "retourne le plus petit rang parmi les groupes du joueur (multi-groupes)" do
      create(:user_level, user: user, level: g1)
      create(:user_level, user: user, level: g2)
      registration = create(:registration, user: user, session: session_record, status: :confirmed)

      expect(registration.priority_rank).to eq(1)
    end

    it "retourne le rang du groupe secondaire quand le joueur n'est que G2" do
      create(:user_level, user: user, level: g2)
      registration = create(:registration, user: user, session: session_record, status: :confirmed)

      expect(registration.priority_rank).to eq(2)
    end

    it "retourne 0 hors entraînement" do
      free_play = create(:session, :jeu_libre, :terrain_2, price: 300,
        start_at: 3.hours.from_now, end_at: 4.hours.from_now)
      registration = create(:registration, user: user, session: free_play, status: :confirmed)

      expect(registration.priority_rank).to eq(0)
    end
  end
end
