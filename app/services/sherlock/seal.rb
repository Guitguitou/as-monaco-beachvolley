# frozen_string_literal: true

require "openssl"
require "digest"

module Sherlock
  # Calcule et vérifie le sceau qui authentifie les échanges avec Sherlock's,
  # dans les deux sens : la requête de paiement que l'on poste, et les réponses
  # que LCL nous renvoie (retour navigateur comme webhook).
  #
  # Deux algorithmes existent selon le contrat :
  # - "HMAC-SHA-256" : HMAC(Data, secret), qui doit être annoncé dans le Data
  # - "sha256"       : SHA256(Data + secret), historique et valeur par défaut
  class Seal
    HMAC_ALGORITHM = "HMAC-SHA-256"
    DEFAULT_ALGORITHM = "sha256"
    DEVELOPMENT_SECRET = "development-secret"

    def self.from_env
      new(secret: secret_from_env, algorithm: ENV.fetch("SHERLOCK_SEAL_ALGO", DEFAULT_ALGORITHM))
    end

    # En dev et en test on veut pouvoir dérouler le flux complet sans secret
    # LCL ; en production son absence doit rester une erreur bruyante.
    def self.secret_from_env
      ENV.fetch("SHERLOCK_API_KEY") do
        raise KeyError, 'key not found: "SHERLOCK_API_KEY"' unless Rails.env.local?

        DEVELOPMENT_SECRET
      end
    end
    private_class_method :secret_from_env

    def initialize(secret:, algorithm: DEFAULT_ALGORITHM)
      @secret = secret
      @algorithm = algorithm
    end

    def compute(data)
      if hmac?
        OpenSSL::HMAC.hexdigest("SHA256", secret, data)
      else
        Digest::SHA256.hexdigest(data + secret)
      end
    end

    def valid?(data, seal)
      return false if data.blank? || seal.blank?

      ActiveSupport::SecurityUtils.secure_compare(compute(data), seal)
    end

    # Seul l'algorithme non historique doit être déclaré à Sherlock's.
    def declared_algorithm
      algorithm if hmac?
    end

    private

    attr_reader :secret, :algorithm

    def hmac?
      algorithm == HMAC_ALGORITHM
    end
  end
end
