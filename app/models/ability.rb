# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new

    if user.admin?
      can :manage, :all
      return
    end

    # Base permissions for all authenticated users
    if user.id.present? && !user.disabled?
      can :read, Session
      can :read, Stage
      can :read, User, id: user.id

      # Packs : Licences toujours accessibles, autres seulement si activé
      can :read, Pack, pack_type: 'licence'
      can :buy, Pack, pack_type: 'licence'
      
      if user.activated?
        can :read, Pack  # Tous les packs si activé
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
      can :manage, Session
      cannot :cancel, Session
      can :manage, Registration
    end
  end
end
