module Users
  class BootstrapAccount
    def self.call(user:, legacy_level:, initialize_balance: true, assign_legacy_level: true)
      new(
        user: user,
        legacy_level: legacy_level,
        initialize_balance: initialize_balance,
        assign_legacy_level: assign_legacy_level
      ).call
    end

    def initialize(user:, legacy_level:, initialize_balance:, assign_legacy_level:)
      @user = user
      @legacy_level = legacy_level
      @initialize_balance = initialize_balance
      @assign_legacy_level = assign_legacy_level
    end

    def call
      create_balance_if_missing if initialize_balance
      apply_legacy_level if assign_legacy_level
    end

    private

    attr_reader :user, :legacy_level, :initialize_balance, :assign_legacy_level

    def create_balance_if_missing
      user.create_balance(amount: 0) unless user.balance.present?
    end

    def apply_legacy_level
      return unless legacy_level.present?

      user.user_levels.find_or_create_by!(level: legacy_level)
    end
  end
end
