require 'rails_helper'

RSpec.describe "Registrations flow", type: :request do
  let(:coach) { create(:user, :coach, activated_at: Time.current) }
  let(:level) { create(:level) }
  let(:player) { create(:user, level: level, activated_at: Time.current) }
  let(:session_record) { create(:session, session_type: 'entrainement', terrain: 'Terrain 1', user: coach, levels: [level]) }

  before do
    create(:credit_transaction, user: player, amount: 1_000)
  end

  # Before 17:00 on the session day so `past_registration_deadline?` does not block players
  # (factory uses start_at 1.hour.from_now, often still "today" when the suite runs after 17h).
  describe "with clock before 17h on the session day" do
    before { travel_to(Time.zone.parse("2025-06-10 10:00")) }
    after { travel_back }

  it "redirects to session show with calendar context params after registration" do
    # Dedicated session so this example does not register the player on `session_record`
    # (other examples depend on a fresh session_record).
    other_session = create(:session, session_type: "entrainement", terrain: "Terrain 1", user: coach, levels: [level])
    sign_in player, scope: :user
    d = other_session.start_at.to_date.iso8601
    post session_registrations_path(other_session), params: { view: "calendar", date: d, terrain: "Terrain 1" }

    expect(response).to redirect_to(
      session_path(other_session, view: "calendar", date: d, terrain: "Terrain 1")
    )
  end

  it 'registers and unregisters a user with transactions' do
    sign_in player, scope: :user
    s = create(:session, session_type: "entrainement", terrain: "Terrain 1", user: coach, levels: [level])

    post session_registrations_path(s)
    expect(flash[:alert]).to be_blank
    expect(flash[:notice]).to include("Inscription")
    expect(player.reload.balance.amount).to eq(1000 - s.price)

    # Unregister and assert refund behavior based on cancellation deadline
    refundable = !s.entrainement? || s.cancellation_deadline_at.blank? || Time.current <= s.cancellation_deadline_at
    # Nested singular resource requires an id; controller finds by current user
    delete session_registration_path(s, id: "current")
    expect(flash[:alert]).to be_blank
    expect(player.reload.balance.amount).to eq(1000 - s.price + (refundable ? s.price : 0))
  end

  it 'prevents registration if overlapping with another confirmed session' do
    sign_in player, scope: :user
    post session_registrations_path(session_record)
    overlapping = create(:session, session_type: 'entrainement', terrain: 'Terrain 2', user: coach, levels: [level], start_at: session_record.start_at + 5.minutes, end_at: session_record.end_at + 5.minutes)

    expect {
      post session_registrations_path(overlapping)
    }.not_to change { player.reload.credit_transactions.count }

    follow_redirect!
    expect(response.body).to include('même créneau')
  end

  it 'promotes the first waitlisted user when a confirmed user unregisters' do
    sign_in player, scope: :user
    session_record.update!(max_players: 1)

    # First player registers and takes the only slot
    post session_registrations_path(session_record)
    expect(session_record.reload.registrations.confirmed.count).to eq(1)

    # Second player with enough credits joins waitlist
    second = create(:user, level: level, activated_at: Time.current)
    create(:credit_transaction, user: second, amount: 1_000)
    sign_in second, scope: :user
    post session_registrations_path(session_record), params: { waitlist: true }
    expect(session_record.reload.registrations.waitlisted.count).to eq(1)

    # First player unregisters, second should be promoted automatically
    sign_in player, scope: :user
    expect {
      delete session_registration_path(session_record, id: "current")
    }.to change { session_record.reload.registrations.confirmed.count }.by(0) # remains 1, different user

    expect(session_record.registrations.confirmed.first.user).to eq(second)
    expect(second.reload.balance.amount).to be <= 1000 - session_record.price
  end
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
             # Ouvert il y a > 24h pour éviter la règle « priorité licence compétition » dans les tests 17h
             registration_opens_at: (today - 2.days).change(hour: 9, min: 0))
    end
    let(:admin) { create(:user, admin: true, activated_at: Time.current) }
    let(:target_user) { create(:user, level: level, activated_at: Time.current) }

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

      sign_in admin, scope: :user

      expect {
        post session_registrations_path(session_today), params: { user_id: target_user.id }
      }.to change { session_today.reload.registrations.count }.by(1)
        .and change { target_user.reload.balance.amount }.by(-session_today.price)

      expect(response).to redirect_to(session_path(session_today))
      expect(flash[:notice]).to include("Inscription réussie")
    end

    it 'blocks regular user from registering after 17h deadline' do
      # Simulate time after 17h
      travel_to(today.change(hour: 18, min: 0))

      sign_in target_user, scope: :user

      expect {
        post session_registrations_path(session_today)
      }.not_to change { session_today.reload.registrations.count }

      follow_redirect!
      expect(response.body).to include('Les inscriptions sont closes')
      expect(response.body).to include('17h')
    end
  end
end
