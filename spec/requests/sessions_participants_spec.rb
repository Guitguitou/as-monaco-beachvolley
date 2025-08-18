require 'rails_helper'

RSpec.describe "Sessions participants sync (public flow)", type: :request do
  let(:coach) { create(:user, :coach) }
  let(:level) { create(:level) }
  let(:player) { create(:user, level: level) }

  before do
    create(:credit_transaction, user: player, amount: 1_000)
    login_as coach, scope: :user
  end

  it 'creates a payment transaction for selected participants on create' do
    params = {
      session: {
        title: 'Entrainement du soir',
        description: 'Test',
        session_type: 'entrainement',
        terrain: 'Terrain 1',
        user_id: coach.id,
        start_at: 1.hour.from_now.change(sec: 0).strftime('%Y-%m-%dT%H:%M'),
        end_at: 2.hours.from_now.change(sec: 0).strftime('%Y-%m-%dT%H:%M'),
        max_players: 12,
        participant_ids: [player.id]
      }
    }

    expect {
      post sessions_path, params: params
    }.to change { player.reload.credit_transactions.count }.by(1)

    last = player.credit_transactions.order(:created_at).last
    expect(last.amount).to eq(-Session::TRAINING_PRICE)
  end
end
