module Sherlock
  class HandleCallback
    attr_reader :params

    def initialize(params)
      @params = params
    end

    def call
      reference = params[:reference] || params[:orderId]
      status = normalize_status(params[:status] || params[:transactionStatus])

      credit_purchase = CreditPurchase.find_by(sherlock_transaction_reference: reference)
      
      unless credit_purchase
        Rails.logger.error("CreditPurchase not found for reference: #{reference}")
        return false
      end

      # Stocker les données brutes du callback
      credit_purchase.update!(
        sherlock_fields: credit_purchase.sherlock_fields.merge(
          callback: params.to_h,
          received_at: Time.current.iso8601
        )
      )

      case status
      when 'paid', 'success', 'authorized'
        handle_success(credit_purchase)
      when 'failed', 'refused', 'error'
        handle_failure(credit_purchase)
      when 'cancelled'
        handle_cancellation(credit_purchase)
      else
        Rails.logger.warn("Unknown status '#{status}' for #{reference}")
      end

      true
    end

    private

    def normalize_status(raw_status)
      return 'paid' unless raw_status
      
      raw_status = raw_status.to_s.downcase
      
      case raw_status
      when 'paid', 'success', 'authorized', '00'
        'paid'
      when 'failed', 'refused', 'error', 'declined'
        'failed'
      when 'cancelled', 'cancel'
        'cancelled'
      else
        raw_status
      end
    end

    def handle_success(credit_purchase)
      return if credit_purchase.paid_status?

      credit_purchase.credit! # Crédite le compte (idempotent)
      
      # Enqueue le job de post-traitement
      PostPaymentFulfillmentJob.perform_later(credit_purchase.id)
      
      Rails.logger.info("Payment successful for #{credit_purchase.sherlock_transaction_reference}")
    end

    def handle_failure(credit_purchase)
      reason = params[:errorMessage] || params[:responseMessage] || 'Unknown error'
      credit_purchase.mark_as_failed!(reason: reason)
      
      Rails.logger.warn("Payment failed for #{credit_purchase.sherlock_transaction_reference}: #{reason}")
    end

    def handle_cancellation(credit_purchase)
      credit_purchase.update!(status: :cancelled)
      
      Rails.logger.info("Payment cancelled for #{credit_purchase.sherlock_transaction_reference}")
    end
  end
end

