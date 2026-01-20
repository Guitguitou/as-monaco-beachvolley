require "sib-api-v3-sdk"

module Brevo
  class TransactionalEmail
    TEMPLATE_ENV_KEY = "BREVO_TEMPLATE_PAYMENT_SUCCESS"
    SENDER_EMAIL_ENV = "BREVO_SENDER_EMAIL"
    SENDER_NAME_ENV = "BREVO_SENDER_NAME"

    class MissingConfigError < StandardError; end

    def initialize(api: default_api, logger: Rails.logger)
      @api = api
      @logger = logger
    end

    def send_payment_confirmation(credit_purchase)
      return if credit_purchase.user.nil?

      send_email(
        template_id: template_id,
        to_email: credit_purchase.user.email,
        to_name: credit_purchase.user.full_name.strip,
        params: email_params(credit_purchase)
      )
    end

    private

    attr_reader :api, :logger

    def send_email(template_id:, to_email:, to_name:, params:)
      payload = Brevo::SendSmtpEmail.new(
        templateId: template_id,
        to: [ { email: to_email, name: to_name } ],
        sender: { email: sender_email, name: sender_name },
        params: params
      )

      api.send_transac_email(payload)
      logger.info("[Brevo] Transactional email sent with template #{template_id} to #{to_email}")
      true
    rescue Brevo::ApiError => error
      logger.error("[Brevo] Failed to send transactional email: #{error.message}")
      raise
    end

    def template_id
      Integer(ENV.fetch(TEMPLATE_ENV_KEY))
    rescue KeyError, ArgumentError => error
      raise MissingConfigError, "Brevo template id missing or invalid (#{TEMPLATE_ENV_KEY}) - #{error.message}"
    end

    def sender_email
      ENV.fetch(SENDER_EMAIL_ENV)
    rescue KeyError
      raise MissingConfigError, "Brevo sender email missing (#{SENDER_EMAIL_ENV})"
    end

    def sender_name
      ENV.fetch(SENDER_NAME_ENV)
    rescue KeyError
      raise MissingConfigError, "Brevo sender name missing (#{SENDER_NAME_ENV})"
    end

    def email_params(credit_purchase)
      {
        user_first_name: credit_purchase.user.first_name,
        user_last_name: credit_purchase.user.last_name,
        purchase_reference: credit_purchase.sherlock_transaction_reference,
        credits: credit_purchase.credits,
        amount_eur: format("%.2f", credit_purchase.amount_eur),
        paid_at_iso: (credit_purchase.paid_at || Time.current).iso8601
      }
    end

    def default_api
      Brevo::TransactionalEmailsApi.new
    end
  end
end
