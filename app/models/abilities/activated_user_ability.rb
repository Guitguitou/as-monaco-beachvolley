# frozen_string_literal: true

# Permissions for activated users.
# Full access to sessions, stages, all packs, and registrations.
module Abilities
  class ActivatedUserAbility < BaseAbility
    protected

    def define_abilities
      return if disabled?

      can :read, User, id: user.id
      can :read, Session
      can :read, Stage
      can :read, Pack
      can :buy, Pack
      can :create, Registration
      can [ :destroy ], Registration, user_id: user.id
      can :read, CreditTransaction, user_id: user.id
    end
  end
end
