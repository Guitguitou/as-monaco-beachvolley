class CreditTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :session, optional: true

  enum :transaction_type, {
    purchase: 0,
    training_payment: 1,
    free_play_payment: 2,
    private_coaching_payment: 3,
    refund: 4,
    manual_adjustment: 5
  }

  validates :amount, presence: true
  after_commit :refresh_balance_amount, on: [:create, :update, :destroy]

  private

  def refresh_balance_amount
    user.balance.update_amount!
  end

end
