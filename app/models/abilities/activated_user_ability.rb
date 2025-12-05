# frozen_string_literal: true

module Abilities
  # Permissions pour les utilisateurs activés
  # Accès complet aux sessions, stages, packs et inscriptions
  class ActivatedUserAbility < BaseAbility
    protected

    def define_abilities
      return if disabled?

      can :read, User, id: user.id
      can :read, Session
      can :read, Stage
      can :read, Pack # Tous les packs
      can :buy, Pack  # Peut acheter tous les packs

      # Registrations (sign-up to sessions) - seulement si activé
      can :create, Registration
      can [:destroy], Registration, user_id: user.id

      # View own credit history
      can :read, CreditTransaction, user_id: user.id
    end
  end
end

