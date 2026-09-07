# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sessions::CardState do
  let(:monday) { Time.zone.parse("2035-01-01 10:00:00") } # un lundi
  let(:level) { create(:level) }
  let(:user) { create(:user, level: level) }

  around { |example| travel_to(monday) { example.run } }

  let(:session_record) do
    start_at = (monday + 8.days).change(hour: 19)
    create(:session, session_type: "entrainement", levels: [ level ], terrain: "Terrain 1",
                     start_at: start_at, end_at: start_at + 1.hour, max_players: 12,
                     registration_opens_at: monday - 1.day)
  end

  def state(weekly_rank: nil, registration: nil)
    described_class.new(
      session: session_record,
      user: user,
      registration: registration,
      confirmed_count: 0,
      conflict: false,
      balance: 10_000,
      user_level_ids: [ level.id ],
      weekly_rank: weekly_rank
    )
  end

  describe "#weekly_secondary?" do
    it "est faux quand le joueur est prioritaire" do
      expect(state(weekly_rank: 0)).not_to be_weekly_secondary
    end

    it "est vrai quand le joueur est déclassé" do
      expect(state(weekly_rank: 1)).to be_weekly_secondary
    end

    it "est faux hors entraînement" do
      allow(session_record).to receive(:entrainement?).and_return(false)
      expect(state(weekly_rank: 1)).not_to be_weekly_secondary
    end
  end

  # Le critère A déclasse, il ne bloque jamais : le bouton reste actionnable.
  describe "non-régression de l'action" do
    subject(:card) { state(weekly_rank: 1) }

    it { expect(card).to be_actionable }
    it { expect(card.action).to eq(:register) }
    it { expect(card.blocked_reason).to be_nil }
    it { expect(card.action_label).to eq("Je m'inscris") }
  end

  describe "#weekly_notice" do
    it "est absent quand le joueur est prioritaire" do
      expect(state(weekly_rank: 0).weekly_notice).to be_nil
    end

    it "annonce le déclassement avant l'inscription" do
      expect(state(weekly_rank: 1).weekly_notice).to include("2e entraînement de la semaine")
    end

    it "annonce le risque de démotion une fois inscrit" do
      create(:credit_transaction, user: user, amount: 10_000)
      registration = create(:registration, user: user, session: session_record, status: :confirmed)
      notice = state(weekly_rank: 1, registration: registration).weekly_notice

      expect(notice).to include("tu repasses en liste d'attente")
    end

    it "explique la position en liste d'attente" do
      registration = create(:registration, :waitlisted, user: user, session: session_record)
      notice = state(weekly_rank: 1, registration: registration).weekly_notice

      expect(notice).to include("tu passes après les joueurs")
    end
  end
end
