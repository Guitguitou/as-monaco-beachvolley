class Balance < ApplicationRecord
  belongs_to :user

  def update_amount!
    update!(amount: user.credit_transactions.sum(:amount))
  end
end
