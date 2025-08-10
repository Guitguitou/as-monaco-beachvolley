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
  validates :reason, length: { maximum: 255 }, allow_nil: true
  after_commit :refresh_balance_amount, on: [:create, :update, :destroy]
  before_validation :default_reason

  private

  def refresh_balance_amount
    user.balance.update_amount!
  end

  def default_reason
    self.reason = "manual" if reason.blank? && manual_adjustment?
  end
end
