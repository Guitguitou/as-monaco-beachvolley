module Credits
  class ApplyTransactionDelta
    def self.call(user:, delta:)
      user.balance.update!(amount: (user.balance.amount || 0) + delta)
    end
  end
end
