# frozen_string_literal: true

# Balance model representing a user's credit balance.
#
# Balance is automatically maintained by CreditTransaction callbacks.
# Can be manually recalculated using update_amount! if needed.
class Balance < ApplicationRecord
  belongs_to :user

  def update_amount!
    update!(amount: user.credit_transactions.sum(:amount))
  end
end
