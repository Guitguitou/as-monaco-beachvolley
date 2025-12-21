# frozen_string_literal: true

# Permissions for financial managers.
# Limited access to dashboard and purchase history.
module Abilities
  class FinancialManagerAbility < BaseAbility
    protected

    def define_abilities
      return if disabled?
      can :read, :admin_dashboard
      can :read, CreditPurchase
    end
  end
end
