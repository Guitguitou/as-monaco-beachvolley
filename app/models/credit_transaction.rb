# frozen_string_literal: true

# CreditTransaction model representing credit transactions (purchases, payments, refunds).
#
# Handles:
# - Automatic balance updates via callbacks
# - Transaction types: purchase, training_payment, free_play_payment, private_coaching_payment, refund, manual_adjustment
# - Incremental balance updates to preserve existing balance baseline
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
  after_create_commit :apply_amount_delta
  after_update_commit :apply_amount_update_delta
  after_destroy_commit :apply_amount_destroy_delta

  scope :payments, -> { where(transaction_type: [ transaction_types[:training_payment], transaction_types[:free_play_payment], transaction_types[:private_coaching_payment] ]) }
  scope :refunds, -> { where(transaction_type: transaction_types[:refund]) }
  scope :revenue_transactions, -> { where(transaction_type: [ transaction_types[:training_payment], transaction_types[:free_play_payment], transaction_types[:private_coaching_payment], transaction_types[:refund] ]) }
  scope :in_period, ->(start_date, end_date) { where(created_at: start_date..end_date) }

  private

  def apply_amount_delta
    user.balance.update!(amount: (user.balance.amount || 0) + amount)
  end

  def apply_amount_update_delta
    previous = saved_change_to_amount? ? saved_change_to_amount.first : amount
    delta = amount - previous
    return if delta.zero?

    user.balance.update!(amount: (user.balance.amount || 0) + delta)
  end

  def apply_amount_destroy_delta
    user.balance.update!(amount: (user.balance.amount || 0) - amount)
  end
end
