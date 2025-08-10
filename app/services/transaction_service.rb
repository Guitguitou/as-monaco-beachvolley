class TransactionService
  def initialize(user, session, amount)
    @user = user
    @session = session
    @amount = amount
  end

  def create_transaction
    CreditTransaction.create!(
      user: @user,
      session: @session,
      transaction_type: transaction_type,
      amount: @amount
    )

    create_balance_transaction(@amount)
  end

  def refund_transaction
    CreditTransaction.create!(
      user: @user,
      session: @session,
      transaction_type: :refund,
      amount: @amount
    )

    create_balance_refund(@amount)
  end

  private

  def create_balance_transaction(amount)
    @user.balance.decrement!(:amount, amount)
  end

  def create_balance_refund(amount)
    @user.balance.increment!(:amount, amount)
  end

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
