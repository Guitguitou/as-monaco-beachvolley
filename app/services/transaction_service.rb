class TransactionService
  def initialize(user, session, amount)
    @user = user
    @session = session
    @amount = amount
  end

  def create_transaction
    # Store payments as negative amounts so balance = sum(transactions)
    recorded_amount = -@amount.to_i

    CreditTransaction.create!(
      user: @user,
      session: @session,
      transaction_type: transaction_type,
      amount: recorded_amount
    )
  end

  def refund_transaction
    # Avoid no-op refund entries
    return if @amount.to_i <= 0

    CreditTransaction.create!(
      user: @user,
      session: @session,
      transaction_type: :refund,
      amount: @amount.to_i
    )
  end

  private

  # Balance is recomputed from transactions via CreditTransaction callback

  def transaction_type
    # For private coaching when amount debits the coach on session creation
    return :private_coaching_payment if @session.coaching_prive? && @user == @session.user

    case @session.session_type
    when "entrainement" then :training_payment
    when "jeu_libre"    then :free_play_payment
    when "coaching_prive" then :private_coaching_payment
    else :purchase
    end
  end
end
