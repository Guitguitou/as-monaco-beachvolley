module Sessions
  class PrivateCoachingChargeService
    def initialize(session:)
      @session = session
    end

    def coach_can_pay?
      session.user&.balance&.amount.to_i >= coaching_price
    end

    def charge_coach!
      TransactionService.new(session.user, session, coaching_price).create_transaction
    end

    private

    attr_reader :session

    def coaching_price
      Session::PRICE_BY_TYPE.fetch("coaching_prive")
    end
  end
end
