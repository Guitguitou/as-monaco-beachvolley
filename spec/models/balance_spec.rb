require 'rails_helper'

RSpec.describe Balance, type: :model do
  let(:user) { create(:user) }

  describe '#update_amount!' do
    it 'sets amount to the sum of credit transactions' do
      # Setup a few transactions (negative = payment, positive = refund/purchase)
      create(:credit_transaction, user: user, amount: -300)
      create(:credit_transaction, user: user, amount: +100)
      create(:credit_transaction, user: user, amount: -50)

      user.balance.update_amount!
      expect(user.balance.reload.amount).to eq(-250)
    end
  end
end
