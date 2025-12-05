# frozen_string_literal: true

module Abilities
  # Permissions pour les coaches
  # Peuvent gérer les sessions et inscriptions, mais seulement annuler leurs propres sessions
  class CoachAbility < ActivatedUserAbility
    protected

    def define_abilities
      super # Hérite des permissions d'utilisateur activé

      return if disabled?

      # Give all CRUD actions except cancel
      can [:read, :create, :update, :destroy], Session
      # Can only cancel their own sessions
      can :cancel, Session, user_id: user.id
      can :manage, Registration
    end
  end
end

