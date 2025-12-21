# frozen_string_literal: true

# app/services/sherlock/handle_callback.rb
module Sherlock
  class HandleCallback
    attr_reader :params

    def initialize(params)
      @params = params.with_indifferent_access
    end

    def call
      reference = params[:reference] || params[:orderId] || params[:transactionReference]
      status    = normalize_status(params[:status] || params[:transactionStatus] || params[:responseCode])

      credit_purchase = CreditPurchase.find_by(sherlock_transaction_reference: reference)

      unless credit_purchase
        Rails.logger.error("[Sherlock] CreditPurchase not found for reference: #{reference}")
        return false
      end

      # Stocker les données brutes du callback pour audit/debug
      credit_purchase.update!(
        sherlock_fields: credit_purchase.sherlock_fields.merge(
          callback: params.to_h,
          received_at: Time.current.iso8601
        )
      )

      case status
      when "paid"
        handle_success(credit_purchase)
      when "failed"
        handle_failure(credit_purchase)
      when "cancelled"
        handle_cancellation(credit_purchase)
      else
        Rails.logger.warn("[Sherlock] Unknown status '#{status}' for #{reference}")
      end

      true
    rescue => e
      Rails.logger.error("[Sherlock] HandleCallback error: #{e.class} - #{e.message}")
      false
    end

    private

    def normalize_status(raw_status)
      return "failed" if raw_status.blank?

      raw_status = raw_status.to_s.downcase

      case raw_status
      when "paid", "success", "authorized", "00"
        "paid"
      when "refused", "failed", "error", "declined", "ko", "97", "99"
        "failed"
      when "cancelled", "cancel", "17"
        "cancelled"
      else
        raw_status
      end
    end

    def handle_success(credit_purchase)
      return if credit_purchase.paid_status?

      credit_purchase.credit! # Crédite la balance utilisateur
      PostPaymentFulfillmentJob.perform_later(credit_purchase.id)

      Rails.logger.info("[Sherlock] Payment successful for #{credit_purchase.sherlock_transaction_reference}")
    end

    def handle_failure(credit_purchase)
      reason = params[:errorMessage] || params[:responseMessage] || "Unknown error"
      credit_purchase.mark_as_failed!(reason: reason)

      Rails.logger.warn("[Sherlock] Payment failed for #{credit_purchase.sherlock_transaction_reference}: #{reason}")
    end

    def handle_cancellation(credit_purchase)
      credit_purchase.update!(status: :cancelled)
      Rails.logger.info("[Sherlock] Payment cancelled for #{credit_purchase.sherlock_transaction_reference}")
    end
  end
end
