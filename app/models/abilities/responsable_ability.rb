# frozen_string_literal: true

# Permissions for responsables.
# Same permissions as coaches.
module Abilities
  class ResponsableAbility < ActivatedUserAbility
    protected

    def define_abilities
      super
      return if disabled?

      can [ :read, :create, :update, :destroy ], Session
      can :cancel, Session, user_id: user.id
      can :manage, Registration
    end
  end
end
