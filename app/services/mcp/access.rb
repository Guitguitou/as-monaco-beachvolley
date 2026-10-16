# frozen_string_literal: true

module Mcp
  # Qui peut connecter son Claude au club : le Staff, tant que son compte est
  # actif. Vérifié à l'autorisation OAuth ET à chaque appel MCP, pour qu'une
  # perte de rôle coupe l'accès sans attendre l'expiration du jeton.
  module Access
    def self.granted_to?(user)
      user.present? && user.staff? && !user.disabled?
    end
  end
end
