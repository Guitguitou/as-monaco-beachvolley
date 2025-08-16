require 'rails_helper'

RSpec.describe User, type: :model do
  it 'creates a balance on create' do
    user = create(:user)
    expect(user.balance).to be_present
    expect(user.balance.amount).to eq(0)
  end

  it '#credit_balance sums credit transactions' do
    user = create(:user)
    create(:credit_transaction, user: user, amount: 100)
    create(:credit_transaction, user: user, amount: -50)
    expect(user.credit_balance).to eq(50)
  end
end
