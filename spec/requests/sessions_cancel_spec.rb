require 'rails_helper'

RSpec.describe "Sessions cancellation", type: :request do
  let(:coach) { create(:user, :coach) }
  let(:level) { create(:level) }

  before do
    # Give coach enough credits so private coaching can be created
    create(:credit_transaction, user: coach, amount: 2_000)
  end

  it 'cancels a training session, refunds participants, and deletes the session' do
    session_record = create(:session, session_type: 'entrainement', terrain: 'Terrain 1', user: coach, levels: [level])
    p1 = create(:user, level: level)
    p2 = create(:user, level: level)
    create(:credit_transaction, user: p1, amount: 1_000)
    create(:credit_transaction, user: p2, amount: 1_000)

    # register both
    post session_registrations_path(session_record)
    sign_in p1
    post session_registrations_path(session_record)
    sign_out p1
    sign_in p2
    post session_registrations_path(session_record)
    sign_out p2

    expect(session_record.registrations.count).to eq(2)

    # cancel as coach
    sign_in coach
    expect {
      post cancel_session_path(session_record)
    }.to change { Session.where(id: session_record.id).count }.by(-1)

    # refunds present (balance increased by price)
    price = session_record.price
    expect(p1.reload.balance.amount).to be >= price
    expect(p2.reload.balance.amount).to be >= price
  end

  it 'cancels a private coaching and refunds the coach' do
    private_session = create(:session, session_type: 'coaching_prive', terrain: 'Terrain 1', user: coach)
    coach_balance_before = coach.balance.amount

    sign_in coach
    post cancel_session_path(private_session)

    expect(Session.exists?(private_session.id)).to be_falsey
    expect(coach.reload.balance.amount).to be > coach_balance_before
  end
end
