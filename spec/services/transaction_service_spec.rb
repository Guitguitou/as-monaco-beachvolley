require 'rails_helper'

RSpec.describe TransactionService do
  let(:user) { create(:user) }
  let(:session_record) { create(:session, terrain: 'Terrain 1') }

  before do
    create(:credit_transaction, user: user, amount: 1000)
  end

  it 'creates a negative amount for payments' do
    expect {
      described_class.new(user, session_record, 300).create_transaction
    }.to change { user.balance.reload.amount }.by(-300)

    last = user.credit_transactions.order(:created_at).last
    expect(last.amount).to eq(-300)
    expect(%w[training_payment free_play_payment private_coaching_payment purchase]).to include(last.transaction_type)
  end

  it "uses the expected transaction type for each session type" do
    free_play = create(:session, :jeu_libre, user: create(:user), start_at: 5.days.from_now, end_at: 5.days.from_now + 2.hours)
    private_coach = create(:user, :coach)
    create(:credit_transaction, user: private_coach, amount: 3_000)
    private_coaching = create(
      :session,
      :coaching_prive,
      user: private_coach,
      terrain: "Terrain 3",
      start_at: 6.days.from_now,
      end_at: 6.days.from_now + 2.hours
    )

    described_class.new(user, free_play, 100).create_transaction
    described_class.new(user, private_coaching, 100).create_transaction

    last_two = user.credit_transactions.order(:created_at).last(2)
    expect(last_two.map(&:transaction_type)).to eq(%w[free_play_payment private_coaching_payment])
  end

  it "uses private_coaching_payment for coach self-debit on private coaching" do
    coach = create(:user, :coach)
    create(:credit_transaction, user: coach, amount: 3_000)
    private_coaching = create(:session, :coaching_prive, user: coach, start_at: 7.days.from_now, end_at: 7.days.from_now + 2.hours)

    described_class.new(coach, private_coaching, 200).create_transaction

    expect(coach.credit_transactions.order(:created_at).last.transaction_type).to eq("private_coaching_payment")
  end

  it 'creates a positive amount for refunds and skips zero' do
    expect {
      described_class.new(user, session_record, 0).refund_transaction
    }.not_to change { user.credit_transactions.count }

    expect {
      described_class.new(user, session_record, 300).refund_transaction
    }.to change { user.balance.reload.amount }.by(300)

    last = user.credit_transactions.order(:created_at).last
    expect(last.transaction_type).to eq('refund')
    expect(last.amount).to eq(300)
  end
end
