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
