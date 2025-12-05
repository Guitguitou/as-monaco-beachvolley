# frozen_string_literal: true

module Abilities
  # Permissions pour les utilisateurs non activés
  # Accès limité aux licences, stages et pages d'infos
  class NonActivatedUserAbility < BaseAbility
    protected

    def define_abilities
      return if disabled?

      can :read, User, id: user.id
      can :read, Pack, pack_type: ['licence', 'stage']
      can :buy, Pack, pack_type: ['licence', 'stage']
      can :read, Stage
      # Access to infos pages (handled in routes, no specific permission needed)
    end
  end
end

