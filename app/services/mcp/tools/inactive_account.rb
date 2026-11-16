# frozen_string_literal: true

module Mcp
  module Tools
    # Explique pourquoi un joueur n'a pas de Compte actif (cf. GLOSSARY.md).
    module InactiveAccount
      def self.message(player)
        missing = player.licence_payee? ? "son dossier n'est pas encore complet" : "sa licence n'est pas payée"
        "#{player.full_name} ne peut pas réserver : #{missing}."
      end
    end
  end
end
