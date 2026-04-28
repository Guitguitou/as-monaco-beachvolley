class CreditTransaction < ApplicationRecord
  belongs_to :user
  belongs_to :session, optional: true
  attr_accessor :skip_side_effect_callbacks

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
  after_create_commit :apply_amount_delta
  after_create_commit :check_low_credits_notification_after_create
  after_update_commit :apply_amount_update_delta
  after_update_commit :check_low_credits_notification_after_update
  after_destroy_commit :apply_amount_destroy_delta
  after_destroy_commit :check_low_credits_notification_after_destroy

  scope :payments, -> { where(transaction_type: [transaction_types[:training_payment], transaction_types[:free_play_payment], transaction_types[:private_coaching_payment]]) }
  scope :refunds, -> { where(transaction_type: transaction_types[:refund]) }
  scope :revenue_transactions, -> { where(transaction_type: [transaction_types[:training_payment], transaction_types[:free_play_payment], transaction_types[:private_coaching_payment], transaction_types[:refund]]) }
  scope :in_period, ->(start_date, end_date) { where(created_at: start_date..end_date) }

  private

  def apply_amount_delta
    return if skip_side_effect_callbacks

    Credits::ApplyTransactionDelta.call(user: user, delta: amount)
  end

  def apply_amount_update_delta
    return if skip_side_effect_callbacks

    previous = saved_change_to_amount? ? saved_change_to_amount.first : amount
    delta = amount - previous
    return if delta.zero?

    Credits::ApplyTransactionDelta.call(user: user, delta: delta)
  end

  def apply_amount_destroy_delta
    return if skip_side_effect_callbacks

    Credits::ApplyTransactionDelta.call(user: user, delta: -amount)
  end

  def check_low_credits_notification_after_create
    return if skip_side_effect_callbacks

    # Règle 3: Notifier si les crédits passent sous 500
    # Le balance a déjà été mis à jour par apply_amount_delta
    # Le solde avant était donc current_balance - amount
    user.balance.reload
    current_balance = user.balance.amount
    previous_balance = current_balance - amount
    Credits::LowBalanceNotifier.call(user: user, previous_balance: previous_balance, current_balance: current_balance)
  end

  def check_low_credits_notification_after_update
    return if skip_side_effect_callbacks

    # Règle 3: Notifier si les crédits passent sous 500
    # Calculer le solde avant cette modification
    user.balance.reload
    current_balance = user.balance.amount
    old_amount = saved_change_to_amount? ? saved_change_to_amount.first : amount
    delta = amount - old_amount
    previous_balance = current_balance - delta
    Credits::LowBalanceNotifier.call(user: user, previous_balance: previous_balance, current_balance: current_balance)
  end

  def check_low_credits_notification_after_destroy
    return if skip_side_effect_callbacks

    # Règle 3: Notifier si les crédits passent sous 500
    # Le balance a déjà été mis à jour par apply_amount_destroy_delta
    # Le solde avant était donc current_balance + amount
    user.balance.reload
    current_balance = user.balance.amount
    previous_balance = current_balance + amount
    Credits::LowBalanceNotifier.call(user: user, previous_balance: previous_balance, current_balance: current_balance)
  end

end
