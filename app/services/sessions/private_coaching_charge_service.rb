module Sessions
  class PrivateCoachingChargeService
    def initialize(session:, rules: ClubRules.current)
      @session = session
      @rules = rules
    end

    def coach_can_pay?
      session.user&.balance&.amount.to_i >= coaching_price
    end

    def charge_coach!
      TransactionService.new(session.user, session, coaching_price).create_transaction
    end

    private

    attr_reader :session, :rules

    def coaching_price
      rules.price_for("coaching_prive")
    end
  end
end
