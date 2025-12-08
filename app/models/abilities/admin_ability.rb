# frozen_string_literal: true

# Permissions for admin users.
# Admins have access to everything.
module Abilities
  class AdminAbility < BaseAbility
    protected

    def define_abilities
      can :manage, :all
    end
  end
end
