# frozen_string_literal: true

module Abilities
  # Permissions pour les administrateurs
  # Les admins ont accès à tout
  class AdminAbility < BaseAbility
    protected

    def define_abilities
      can :manage, :all
    end
  end
end

