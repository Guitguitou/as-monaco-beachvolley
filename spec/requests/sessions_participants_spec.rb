require 'rails_helper'

RSpec.describe "Sessions participants sync (public flow)", type: :request do
  let(:coach) { create(:user, :coach) }
  let(:level) { create(:level) }
  let(:player) { create(:user, level: level) }

  before do
    create(:credit_transaction, user: player, amount: 1_000)
    login_as coach, scope: :user
  end

  # Avant 17 h, l'heure limite d'inscription du jour J.
  around { |example| travel_to(Time.zone.local(2026, 10, 14, 10)) { example.run } }

  it 'creates a payment transaction for selected participants on create' do
    params = {
      session: {
        title: 'Entrainement du soir',
        description: 'Test',
        session_type: 'entrainement',
        terrain_id: FactoryHelpers.resolve_terrain('Terrain 1').id,
        user_id: coach.id,
        start_at: 1.hour.from_now.change(sec: 0).strftime('%Y-%m-%dT%H:%M'),
        end_at: 2.hours.from_now.change(sec: 0).strftime('%Y-%m-%dT%H:%M'),
        max_players: 12,
        participant_ids: [ player.id ]
      }
    }

    expect {
      post sessions_path, params: params
    }.to change { player.reload.credit_transactions.count }.by(1)

    last = player.credit_transactions.order(:id).last
    expect(last.amount).to eq(-ClubRules.current.price_for("entrainement"))
  end

  context "when a participant is removed after the cancellation deadline" do
    let(:admin) { create(:user, admin: true) }
    let(:other) { create(:user, level: level) }
    let(:training) do
      create(:session, user: coach, levels: [ level ],
             start_at: 1.day.from_now.change(hour: 18), end_at: 1.day.from_now.change(hour: 20))
    end

    before do
      create(:credit_transaction, user: other, amount: 1_000)
      [ player, other ].each { |user| create(:registration, user: user, session: training, status: :confirmed) }
      training.update_columns(cancellation_deadline_at: 1.hour.ago)
    end

    def remove_player(excused_ids:)
      patch session_path(training), params: { session: { participant_ids: [ other.id ], excused_ids: excused_ids } }
    end

    it "refunds the player the staff excused" do
      login_as admin, scope: :user

      expect { remove_player(excused_ids: [ player.id ]) }.to change { player.reload.credit_balance }.by(training.price)
      expect(LateCancellation.counted.where(user: player)).to be_empty
    end

    it "ignores excuses sent by a supervisor" do
      expect { remove_player(excused_ids: [ player.id ]) }.not_to change { player.reload.credit_balance }
      expect(LateCancellation.where(user: player, session: training)).to exist
    end
  end
end
