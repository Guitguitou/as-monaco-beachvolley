# frozen_string_literal: true

module Abilities
  # Permissions pour les responsables financiers
  # Accès limité au dashboard et historique des achats
  class FinancialManagerAbility < BaseAbility
    protected

    def define_abilities
      can :read, :admin_dashboard
      can :read, CreditPurchase
    end
  end
end

