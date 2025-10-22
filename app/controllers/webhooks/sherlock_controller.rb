module Webhooks
  class SherlockController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :verify_signature!, only: [:create]

    def create
      # Enqueue le job pour traiter le callback de manière asynchrone
      SherlockCallbackJob.perform_later(callback_params.to_h)
      
      head :ok
    end

    private

    def callback_params
      params.permit(
        :reference, :orderId, :status, :transactionStatus,
        :amount, :currency, :responseCode, :responseMessage,
        :errorMessage, :transactionId, :threeds_ls_code
      )
    end

    def verify_signature!
      # En développement, on skip la vérification
      return if Rails.env.development? || Rails.env.test?
      
      # Vérifier la signature HMAC
      provided_signature = request.headers['X-Sherlock-Signature'].to_s
      body = request.raw_post
      secret = ENV.fetch('SHERLOCK_WEBHOOK_TOKEN', '')
      
      return if secret.blank? # Pas de token configuré
      
      computed_signature = OpenSSL::HMAC.hexdigest('SHA256', secret, body)
      
      unless ActiveSupport::SecurityUtils.secure_compare(provided_signature, computed_signature)
        Rails.logger.error("Invalid Sherlock webhook signature")
        head :unauthorized
      end
    end
  end
end

