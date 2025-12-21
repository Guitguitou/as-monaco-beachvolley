# frozen_string_literal: true

# app/controllers/webhooks/sherlock_controller.rb
class Webhooks::SherlockController < ActionController::API
  def receive
    data = params[:Data].to_s
    seal = params[:Seal].to_s

    return head :bad_request unless validate_webhook_data(data, seal)
    return head :unauthorized unless validate_seal(data, seal)

    process_webhook(data)
    head :ok
  rescue StandardError => e
    Rails.logger.error("[Sherlock:webhook] #{e.class}: #{e.message}")
    head :internal_server_error
  end

  private

  def validate_webhook_data(data, seal)
    return true if data.present? && seal.present?

    Rails.logger.warn("[Sherlock] Missing Data or Seal in webhook")
    false
  end

  def validate_seal(data, seal)
    validator = Sherlock::WebhookValidationService.new(data, seal)
    return true if validator.valid?

    Rails.logger.warn("[Sherlock] Invalid Seal for webhook")
    false
  end

  def process_webhook(data)
    parsed = Sherlock::DataParser.parse(data)
    normalized = normalize_webhook_data(parsed)

    Rails.logger.info("[Sherlock:webhook] ref=#{normalized['reference']} rc=#{parsed['responseCode']} ts=#{parsed['transactionStatus']}")

    SherlockCallbackJob.perform_later(normalized)
  end

  def normalize_webhook_data(parsed)
    parsed.merge(
      "reference" => parsed["orderId"] || parsed["transactionReference"],
      "status" => parsed["transactionStatus"] || parsed["responseCode"]
    )
  end
end
