# frozen_string_literal: true

module Lcl
  class Client
    class ConfigurationError < StandardError; end
    class ApiError < StandardError; end

    attr_reader :merchant_id, :certificate_path, :private_key_path, :base_url

    def initialize
      @merchant_id = ENV.fetch('LCL_MERCHANT_ID', nil)
      @certificate_path = ENV.fetch('LCL_CERTIFICATE_PATH', nil)
      @private_key_path = ENV.fetch('LCL_PRIVATE_KEY_PATH', nil)
      @base_url = ENV.fetch('LCL_BASE_URL') { default_base_url }

      validate_configuration!
    end

    # Vérifie si la configuration est valide
    def configured?
      merchant_id.present? && certificate_path.present? && private_key_path.present?
    end

    # Retourne le client de paiement
    def payment
      @payment ||= Lcl::Api::Payment.new(self)
    end

    # Retourne le gestionnaire de signatures
    def signature
      @signature ||= Lcl::Signature.new(self)
    end

    # Charge la clé privée
    def private_key
      @private_key ||= OpenSSL::PKey::RSA.new(File.read(private_key_path))
    rescue Errno::ENOENT => e
      raise ConfigurationError, "Fichier de clé privée introuvable: #{private_key_path}"
    rescue OpenSSL::PKey::RSAError => e
      raise ConfigurationError, "Clé privée invalide: #{e.message}"
    end

    # Charge le certificat
    def certificate
      @certificate ||= OpenSSL::X509::Certificate.new(File.read(certificate_path))
    rescue Errno::ENOENT => e
      raise ConfigurationError, "Fichier de certificat introuvable: #{certificate_path}"
    rescue OpenSSL::X509::CertificateError => e
      raise ConfigurationError, "Certificat invalide: #{e.message}"
    end

    private

    def default_base_url
      Rails.env.production? ? 'https://secure.lcl.fr' : 'https://recette.secure.lcl.fr'
    end

    def validate_configuration!
      unless configured?
        missing = []
        missing << 'LCL_MERCHANT_ID' unless merchant_id.present?
        missing << 'LCL_CERTIFICATE_PATH' unless certificate_path.present?
        missing << 'LCL_PRIVATE_KEY_PATH' unless private_key_path.present?
        
        raise ConfigurationError, "Configuration LCL manquante: #{missing.join(', ')}"
      end
    end
  end
end

