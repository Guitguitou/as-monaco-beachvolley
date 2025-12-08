# frozen_string_literal: true

# Permissions for coaches.
# Can manage sessions and registrations, but can only cancel their own sessions.
module Abilities
  class CoachAbility < ActivatedUserAbility
    protected

    def define_abilities
      super
      return if disabled?

      can [:read, :create, :update, :destroy], Session
      can :cancel, Session, user_id: user.id
      can :manage, Registration
    end
  end
end
