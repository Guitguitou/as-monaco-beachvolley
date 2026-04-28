module Credits
  class RecordTransaction
    def self.call(user:, transaction_type:, amount:, session: nil)
      new(user: user, transaction_type: transaction_type, amount: amount, session: session).call
    end

    def initialize(user:, transaction_type:, amount:, session:)
      @user = user
      @transaction_type = transaction_type
      @amount = amount.to_i
      @session = session
    end

    def call
      previous_balance = user.balance.amount || 0

      transaction = CreditTransaction.create!(
        user: user,
        session: session,
        transaction_type: transaction_type,
        amount: amount
      )

      Credits::ApplyTransactionDelta.call(user: user, delta: amount)
      current_balance = previous_balance + amount
      Credits::LowBalanceNotifier.call(
        user: user,
        previous_balance: previous_balance,
        current_balance: current_balance
      )

      transaction
    end

    private

    attr_reader :user, :transaction_type, :amount, :session
  end
end
