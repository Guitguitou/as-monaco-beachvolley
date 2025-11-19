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

    # Unregister and assert refund behavior based on cancellation deadline
    refundable = !session_record.entrainement? || session_record.cancellation_deadline_at.blank? || Time.current <= session_record.cancellation_deadline_at
    # Nested singular resource requires an id; controller finds by current user
    expect {
      delete session_registration_path(session_record, id: 'current')
    }.to change { player.reload.balance.amount }.by(refundable ? session_record.price : 0)
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

  context 'when registration deadline has passed (after 17h)' do
    let(:today) { Time.zone.parse('2024-11-07 10:00:00') }
    let(:session_today) do
      create(:session,
             session_type: 'entrainement',
             terrain: 'Terrain 1',
             user: coach,
             levels: [level],
             start_at: today.change(hour: 19, min: 0), # 19h aujourd'hui
             end_at: today.change(hour: 20, min: 30),
             registration_opens_at: today.change(hour: 9, min: 0))
    end
    let(:admin) { create(:user, admin: true) }
    let(:target_user) { create(:user, level: level) }

    before do
      travel_to(today)
      create(:credit_transaction, user: target_user, amount: 1_000)
    end

    after do
      travel_back
    end

    it 'allows admin to add a user after 17h deadline' do
      # Simulate time after 17h
      travel_to(today.change(hour: 18, min: 0))

      login_as admin, scope: :user

      expect {
        post session_registrations_path(session_today), params: { user_id: target_user.id }
      }.to change { session_today.reload.registrations.count }.by(1)
        .and change { target_user.reload.balance.amount }.by(-session_today.price)

      follow_redirect!
      expect(response.body).to include('Inscription réussie')
    end

    it 'blocks regular user from registering after 17h deadline' do
      # Simulate time after 17h
      travel_to(today.change(hour: 18, min: 0))

      login_as target_user, scope: :user

      expect {
        post session_registrations_path(session_today)
      }.not_to change { session_today.reload.registrations.count }

      follow_redirect!
      expect(response.body).to include('Les inscriptions sont closes')
      expect(response.body).to include('17h')
    end
  end
end
