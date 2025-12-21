# frozen_string_literal: true

# Permissions for non-activated users.
# Limited access to licences, stages, and info pages.
module Abilities
  class NonActivatedUserAbility < BaseAbility
    protected

    def define_abilities
      return if disabled?

      can :read, User, id: user.id
      can :read, Pack, pack_type: [ "licence", "stage" ]
      can :buy, Pack, pack_type: [ "licence", "stage" ]
      can :read, Stage
    end
  end
end
