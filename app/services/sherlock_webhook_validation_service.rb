# frozen_string_literal: true

# Service to validate Sherlock webhook seal
module Sherlock
  class WebhookValidationService
    def initialize(data, seal)
      @data = data
      @seal = seal
    end

    def valid?
      return false unless @data.present? && @seal.present?

      computed_seal == @seal
    rescue StandardError => e
      Rails.logger.error("[Sherlock] Seal verification error: #{e.class} #{e.message}")
      false
    end

    private

    def computed_seal
      secret = ENV.fetch("SHERLOCK_API_KEY")
      algo = ENV.fetch("SHERLOCK_SEAL_ALGO", "sha256")

      if algo == "HMAC-SHA-256"
        OpenSSL::HMAC.hexdigest("SHA256", secret, @data)
      else
        Digest::SHA256.hexdigest(@data + secret)
      end
    end
  end
end
