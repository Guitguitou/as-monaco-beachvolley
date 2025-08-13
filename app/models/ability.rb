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
    if user.id.present?
      can :read, Session
      can :read, User, id: user.id

      # Registrations (sign-up to sessions)
      can :create, Registration
      can [:destroy], Registration, user_id: user.id

      # View own credit history
      can :read, CreditTransaction, user_id: user.id
    end

    # Elevated roles
    if user.coach? || user.responsable?
      can :manage, Session
      can :manage, Registration
    end
  end
end
