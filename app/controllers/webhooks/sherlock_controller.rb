# app/controllers/webhooks/sherlock_controller.rb
class Webhooks::SherlockController < ActionController::API
  # POST /webhooks/sherlock
  def receive
    data = params[:Data].to_s
    seal = params[:Seal].to_s

    unless data.present? && seal.present?
      Rails.logger.warn("[Sherlock] Missing Data or Seal in webhook")
      return head :bad_request
    end

    unless valid_seal?(data, seal)
      Rails.logger.warn("[Sherlock] Invalid Seal for webhook")
      return head :unauthorized
    end

    parsed = Sherlock::DataParser.parse(data) # "k=v|k=v" -> hash

    # 🔑 Normalisation : on passe à HandleCallback ce qu'il attend
    normalized = parsed.merge(
      "reference" => parsed["orderId"] || parsed["transactionReference"],
      "status"    => parsed["transactionStatus"] || parsed["responseCode"]
    )

    Rails.logger.info("[Sherlock:webhook] ref=#{normalized['reference']} rc=#{parsed['responseCode']} ts=#{parsed['transactionStatus']}")

    # Enfile le job (ou appelle HandleCallback.new(normalized).call si tu préfères synchrone)
    SherlockCallbackJob.perform_later(normalized)

    head :ok
  rescue => e
    Rails.logger.error("[Sherlock:webhook] #{e.class}: #{e.message}")
    head :internal_server_error
  end

  private

  # Aligne l'algo de vérification du Seal sur celui utilisé à l'init
  # SEAL_ALGO = "sha256" (Data+secret) OU "HMAC-SHA-256" (HMAC(Data, secret))
  def valid_seal?(data, seal)
    secret = ENV.fetch("SHERLOCK_API_KEY")
    algo   = ENV.fetch("SHERLOCK_SEAL_ALGO", "sha256")

    computed =
      if algo == "HMAC-SHA-256"
        OpenSSL::HMAC.hexdigest("SHA256", secret, data)
      else # "sha256" par défaut
        Digest::SHA256.hexdigest(data + secret)
      end

    ActiveSupport::SecurityUtils.secure_compare(computed, seal)
  rescue => e
    Rails.logger.error("[Sherlock] Seal verification error: #{e.class} #{e.message}")
    false
  end
end
