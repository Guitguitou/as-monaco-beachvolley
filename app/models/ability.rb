# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    if user.admin?
      can :manage, :all
      return
    end

    # Responsable financier : accès limité au dashboard et historique des achats
    if user.financial_manager?
      can :read, :admin_dashboard
      can :read, CreditPurchase
      return
    end

    # Base permissions for all authenticated users
    if user.id.present? && !user.disabled?
      can :read, User, id: user.id

      # Non-activated users: limited access to licenses, stages and infos
      if !user.activated?
        can :read, Pack, pack_type: ['licence', 'stage']
        can :buy, Pack, pack_type: ['licence', 'stage']
        can :read, Stage
        # Access to infos pages (handled in routes, no specific permission needed)
      else
        # Activated users: full access
        can :read, Session
        can :read, Stage
        can :read, Pack  # Tous les packs
        can :buy, Pack   # Peut acheter tous les packs

        # Registrations (sign-up to sessions) - seulement si activé
        can :create, Registration
        can [:destroy], Registration, user_id: user.id

        # View own credit history
        can :read, CreditTransaction, user_id: user.id
      end
    end

    # Elevated roles
    if (user.coach? || user.responsable?) && !user.disabled?
      # Give all CRUD actions except cancel
      can [:read, :create, :update, :destroy], Session
      # Can only cancel their own sessions
      can :cancel, Session, user_id: user.id
      can :manage, Registration
    end
  end
end
