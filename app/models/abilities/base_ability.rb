# frozen_string_literal: true

# Classe de base pour les abilities
# Suit le pattern Strategy pour séparer les permissions par type d'utilisateur
module Abilities
  class BaseAbility
    include CanCan::Ability

    def initialize(user)
      @user = user || User.new
      define_abilities
    end

    protected

    attr_reader :user

    def define_abilities
      # Override in subclasses
    end

    def disabled?
      user.disabled?
    end

    def activated?
      user.activated?
    end
  end
end

