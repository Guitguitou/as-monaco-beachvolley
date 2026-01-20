require "sib-api-v3-sdk"

Brevo = SibApiV3Sdk unless defined?(Brevo)

if ENV["BREVO_API_KEY"].present?
  Brevo.configure do |config|
    config.api_key["api-key"] = ENV["BREVO_API_KEY"]
    config.timeout = 10
    config.user_agent = "as-monaco-beach-volley/transactional-email"
  end
else
  Rails.logger&.warn("[Brevo] BREVO_API_KEY is not set; transactional emails are disabled")
end
