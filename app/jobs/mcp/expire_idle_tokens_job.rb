# frozen_string_literal: true

module Mcp
  # Révoque les connexions Claude inutilisées depuis 30 jours.
  #
  # Le refresh token tourne à chaque renouvellement (toutes les heures
  # d'usage) : un jeton créé il y a plus de 30 jours et toujours actif est donc
  # celui d'une connexion abandonnée. Doorkeeper n'expire pas les refresh
  # tokens de lui-même.
  class ExpireIdleTokensJob < ApplicationJob
    queue_as :default

    IDLE_AFTER = 30.days

    def perform
      Doorkeeper::AccessToken.where(revoked_at: nil, created_at: ...IDLE_AFTER.ago).find_each(&:revoke)
    end
  end
end
