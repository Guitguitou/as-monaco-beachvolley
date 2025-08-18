require 'rails_helper'

RSpec.describe "Registrations flow", type: :request do
  let(:coach) { create(:user, :coach) }
  let(:level) { create(:level) }
  let(:player) { create(:user, level: level) }
  let(:session_record) { create(:session, session_type: 'entrainement', terrain: 'Terrain 1', user: coach, levels: [level]) }

  before do
    create(:credit_transaction, user: player, amount: 1_000)
  end

  it 'registers and unregisters a user with transactions' do
    login_as player, scope: :user

    expect {
      post session_registrations_path(session_record)
    }.to change { player.reload.balance.amount }.by(-session_record.price)

    # Nested singular resource requires an id; controller finds by current user
    expect {
      delete session_registration_path(session_record, id: 'current')
    }.to change { player.reload.balance.amount }.by(session_record.price)
  end

  it 'prevents registration if overlapping with another confirmed session' do
    login_as player, scope: :user
    post session_registrations_path(session_record)
    overlapping = create(:session, session_type: 'entrainement', terrain: 'Terrain 2', user: coach, levels: [level], start_at: session_record.start_at + 5.minutes, end_at: session_record.end_at + 5.minutes)

    expect {
      post session_registrations_path(overlapping)
    }.not_to change { player.reload.credit_transactions.count }

    follow_redirect!
    expect(response.body).to include('même créneau')
  end
end
