class CreditTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :session, optional: true

  def self.record!(user:, transaction_type:, amount:, session: nil)
    Credits::RecordTransaction.call(
      user: user,
      transaction_type: transaction_type,
      amount: amount,
      session: session
    )
  end

  enum :transaction_type, {
    purchase: 0,
    training_payment: 1,
    free_play_payment: 2,
    private_coaching_payment: 3,
    refund: 4,
    manual_adjustment: 5
  }

  validates :amount, presence: true

  scope :payments, -> { where(transaction_type: [transaction_types[:training_payment], transaction_types[:free_play_payment], transaction_types[:private_coaching_payment]]) }
  scope :refunds, -> { where(transaction_type: transaction_types[:refund]) }
  scope :revenue_transactions, -> { where(transaction_type: [transaction_types[:training_payment], transaction_types[:free_play_payment], transaction_types[:private_coaching_payment], transaction_types[:refund]]) }
  scope :in_period, ->(start_date, end_date) { where(created_at: start_date..end_date) }
end
