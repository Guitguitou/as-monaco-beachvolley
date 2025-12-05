# frozen_string_literal: true

module Abilities
  # Permissions pour les responsables
  # Mêmes permissions que les coaches
  class ResponsableAbility < BaseAbility
    protected

    def define_abilities
      return if disabled?

      # Base permissions for authenticated users
      can :read, User, id: user.id

      # Activated users get full access
      if activated?
        can :read, Session
        can :read, Stage
        can :read, Pack
        can :buy, Pack
        can :create, Registration
        can [:destroy], Registration, user_id: user.id
        can :read, CreditTransaction, user_id: user.id
      end

      # Elevated permissions for responsables
      # Give all CRUD actions except cancel
      can [:read, :create, :update, :destroy], Session
      # Can only cancel their own sessions
      can :cancel, Session, user_id: user.id
      can :manage, Registration
    end
  end
end

