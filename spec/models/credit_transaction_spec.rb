require 'rails_helper'

RSpec.describe CreditTransaction, type: :model do
  let(:user) { create(:user) }

  it 'is valid with valid attributes' do
    ct = build(:credit_transaction, user: user, amount: 100)
    expect(ct).to be_valid
  end

  it 'recomputes balance after commit' do
    expect {
      create(:credit_transaction, user: user, amount: 200)
    }.to change { user.balance.reload.amount }.by(200)
  end

  describe 'transaction_type enum' do
    it 'contains expected keys' do
      expect(CreditTransaction.transaction_types.keys).to include(
        'purchase', 'training_payment', 'free_play_payment', 'private_coaching_payment', 'refund', 'manual_adjustment'
      )
    end
  end
end
