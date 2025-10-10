# frozen_string_literal: true

module Lcl
  class Signature
    attr_reader :client

    def initialize(client)
      @client = client
    end

    # Génère une signature pour les paramètres donnés
    # @param params [Hash] Les paramètres à signer
    # @return [String] La signature encodée en Base64
    def generate(params)
      string_to_sign = build_string_to_sign(params)
      sign_string(string_to_sign)
    end

    # Vérifie la validité d'une signature
    # @param params [Hash] Les paramètres reçus (incluant la signature)
    # @param received_signature [String] La signature reçue
    # @return [Boolean] true si la signature est valide
    def verify(params, received_signature)
      return false if received_signature.blank?

      expected_signature = generate(params)
      secure_compare(received_signature, expected_signature)
    end

    # Extrait et vérifie la signature des paramètres
    # @param params [Hash] Les paramètres incluant :signature
    # @return [Boolean] true si la signature est valide
    def verify_from_params(params)
      params = params.dup.symbolize_keys
      received_signature = params.delete(:signature)
      
      verify(params, received_signature)
    end

    private

    # Construit la chaîne à signer à partir des paramètres
    def build_string_to_sign(params)
      sorted_params = params.sort.to_h
      sorted_params.map { |k, v| "#{k}=#{v}" }.join('&')
    end

    # Signe une chaîne avec la clé privée
    def sign_string(string)
      signature = client.private_key.sign(OpenSSL::Digest::SHA256.new, string)
      Base64.strict_encode64(signature)
    rescue StandardError => e
      raise Client::ApiError, "Erreur lors de la génération de la signature: #{e.message}"
    end

    # Compare deux signatures de manière sécurisée (protection contre les attaques de timing)
    def secure_compare(a, b)
      return false if a.blank? || b.blank? || a.bytesize != b.bytesize

      l = a.unpack("C*")
      r = b.unpack("C*")
      
      res = 0
      l.zip(r) { |x, y| res |= x ^ y.to_i }
      res.zero?
    end
  end
end

