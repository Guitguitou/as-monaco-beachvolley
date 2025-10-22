# app/controllers/webhooks/sherlock_controller.rb
class Webhooks::SherlockController < ActionController::API
  # POST /webhooks/sherlock
  def receive
    data  = params[:Data] || request.raw_post && (parse_raw_post_for_data || params[:Data])
    seal  = params[:Seal] || request.headers["Seal"]
    unless data.present? && seal.present?
      Rails.logger.warn("[Sherlock] Missing Data or Seal in webhook")
      return head :bad_request
    end

    # Verify seal
    unless valid_seal?(data, seal)
      Rails.logger.warn("[Sherlock] Invalid Seal for webhook")
      return head :unauthorized
    end

    parsed = Sherlock::DataParser.parse(data)

    # Enqueue job with parsed hash + raw data (for audits)
    SherlockCallbackJob.perform_later(parsed.merge("_raw_data" => data))

    head :ok
  rescue => e
    Rails.logger.error("[Sherlock] Webhook processing error: #{e.class} #{e.message}")
    head :internal_server_error
  end

  private

  # In case the gateway posts JSON instead of form-data
  def parse_raw_post_for_data
    body = request.raw_post
    return nil if body.blank?

    begin
      json = JSON.parse(body)
      return json["Data"] if json["Data"].present?
    rescue JSON::ParserError
      # fallback: maybe body is form encoded -> Rack will have parsed into params
      nil
    end
  end

  def valid_seal?(data, seal)
    secret = ENV.fetch("SHERLOCK_API_KEY")
    computed = OpenSSL::HMAC.hexdigest("SHA256", secret, data)
    ActiveSupport::SecurityUtils.secure_compare(computed, seal)
  rescue => e
    Rails.logger.error("[Sherlock] Seal verification error: #{e.class} #{e.message}")
    false
  end
end
