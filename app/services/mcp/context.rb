# frozen_string_literal: true

module Mcp
  # Contexte d'un appel MCP : l'utilisateur derrière le jeton et ses droits.
  # Les tools n'ont pas d'autres règles d'accès que celles de l'app (Ability).
  class Context
    attr_reader :user

    def initialize(user:, ability: Ability.new(user))
      @user = user
      @ability = ability
    end

    def authorize!(action, subject)
      @ability.authorize!(action, subject)
    end
  end
end
