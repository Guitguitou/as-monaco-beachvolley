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

  it 'promotes the first waitlisted user when a confirmed user unregisters' do
    login_as player, scope: :user
    session_record.update!(max_players: 1)

    # First player registers and takes the only slot
    post session_registrations_path(session_record)
    expect(session_record.reload.registrations.confirmed.count).to eq(1)

    # Second player with enough credits joins waitlist
    second = create(:user, level: level)
    create(:credit_transaction, user: second, amount: 1_000)
    login_as second, scope: :user
    post session_registrations_path(session_record), params: { waitlist: true }
    expect(session_record.reload.registrations.waitlisted.count).to eq(1)

    # First player unregisters, second should be promoted automatically
    login_as player, scope: :user
    expect {
      delete session_registration_path(session_record, id: 'current')
    }.to change { session_record.reload.registrations.confirmed.count }.by(0) # remains 1, different user

    expect(session_record.registrations.confirmed.first.user).to eq(second)
    expect(second.reload.balance.amount).to be <= 1000 - session_record.price
  end
end
