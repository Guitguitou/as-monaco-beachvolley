# frozen_string_literal: true

# Base class for all specialized abilities.
# Uses Strategy pattern to separate permissions by user type.
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
