# frozen_string_literal: true

# Module principal pour l'intégration LCL/Sherlock
module Lcl
  class << self
    # Retourne une instance du client LCL configuré
    # @return [Lcl::Client]
    def client
      @client ||= Lcl::Client.new
    end

    # Réinitialise le client (utile pour les tests)
    def reset!
      @client = nil
    end
  end
end

# Chargement des dépendances
require_relative 'lcl/client'
require_relative 'lcl/signature'
require_relative 'lcl/api/payment'

