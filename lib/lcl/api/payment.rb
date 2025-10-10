# frozen_string_literal: true

module Lcl
  module Api
    class Payment
      attr_reader :client

      def initialize(client)
        @client = client
      end

      # Crée une nouvelle transaction de paiement
      # @param payment_record [Payment] L'objet Payment ActiveRecord
      # @return [Hash] { success: Boolean, payment_url: String, error: String }
      def create(payment_record)
        params = build_payment_params(payment_record)
        signature = client.signature.generate(params)
        params[:signature] = signature

        payment_url = "#{client.base_url}/payment/init?#{params.to_query}"
        transaction_id = generate_transaction_id(payment_record)

        {
          success: true,
          payment_url: payment_url,
          transaction_id: transaction_id
        }
      rescue StandardError => e
        Rails.logger.error "LCL Payment creation error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        
        {
          success: false,
          error: e.message
        }
      end

      # Traite le callback de retour de paiement
      # @param params [Hash] Les paramètres du callback
      # @return [Hash] { success: Boolean, status: String, error: String }
      def handle_callback(params)
        params = params.deep_symbolize_keys
        
        unless client.signature.verify_from_params(params)
          return {
            success: false,
            error: 'Signature invalide'
          }
        end

        status = map_callback_status(params[:status])
        
        {
          success: true,
          status: status,
          transaction_id: params[:transaction_id],
          external_id: params[:external_id],
          raw_response: params
        }
      rescue StandardError => e
        Rails.logger.error "LCL Callback handling error: #{e.message}"
        
        {
          success: false,
          error: e.message
        }
      end

      # Effectue un remboursement
      # @param payment_record [Payment] L'objet Payment à rembourser
      # @param amount_cents [Integer] Le montant à rembourser (optionnel, par défaut le montant total)
      # @return [Hash] { success: Boolean, refund_id: String, error: String }
      def refund(payment_record, amount_cents: nil)
        amount = amount_cents || payment_record.amount_cents

        params = {
          merchant_id: client.merchant_id,
          transaction_id: payment_record.sherlock_transaction_id,
          amount: amount,
          currency: 'EUR',
          operation: 'refund'
        }

        signature = client.signature.generate(params)
        params[:signature] = signature

        # TODO: Implémenter l'appel API réel pour le remboursement
        # Pour l'instant, retourne une structure de base
        
        {
          success: true,
          refund_id: "REFUND_#{payment_record.id}_#{Time.current.to_i}",
          amount_refunded: amount
        }
      rescue StandardError => e
        Rails.logger.error "LCL Refund error: #{e.message}"
        
        {
          success: false,
          error: e.message
        }
      end

      # Capture un paiement pré-autorisé
      # @param payment_record [Payment] L'objet Payment à capturer
      # @param amount_cents [Integer] Le montant à capturer (optionnel)
      # @return [Hash] { success: Boolean, capture_id: String, error: String }
      def capture(payment_record, amount_cents: nil)
        amount = amount_cents || payment_record.amount_cents

        params = {
          merchant_id: client.merchant_id,
          transaction_id: payment_record.sherlock_transaction_id,
          amount: amount,
          currency: 'EUR',
          operation: 'capture'
        }

        signature = client.signature.generate(params)
        params[:signature] = signature

        # TODO: Implémenter l'appel API réel pour la capture
        
        {
          success: true,
          capture_id: "CAPTURE_#{payment_record.id}_#{Time.current.to_i}",
          amount_captured: amount
        }
      rescue StandardError => e
        Rails.logger.error "LCL Capture error: #{e.message}"
        
        {
          success: false,
          error: e.message
        }
      end

      # Annule un paiement pré-autorisé
      # @param payment_record [Payment] L'objet Payment à annuler
      # @return [Hash] { success: Boolean, cancellation_id: String, error: String }
      def cancel(payment_record)
        params = {
          merchant_id: client.merchant_id,
          transaction_id: payment_record.sherlock_transaction_id,
          operation: 'cancel'
        }

        signature = client.signature.generate(params)
        params[:signature] = signature

        # TODO: Implémenter l'appel API réel pour l'annulation
        
        {
          success: true,
          cancellation_id: "CANCEL_#{payment_record.id}_#{Time.current.to_i}"
        }
      rescue StandardError => e
        Rails.logger.error "LCL Cancellation error: #{e.message}"
        
        {
          success: false,
          error: e.message
        }
      end

      private

      def build_payment_params(payment_record)
        {
          merchant_id: client.merchant_id,
          amount: payment_record.amount_cents,
          currency: 'EUR',
          order_id: payment_record.id,
          customer_email: payment_record.user.email,
          customer_name: payment_record.user.full_name,
          return_url: callback_url,
          cancel_url: cancel_url,
          notify_url: notify_url
        }
      end

      def generate_transaction_id(payment_record)
        "PAY_#{payment_record.id}_#{Time.current.to_i}"
      end

      def map_callback_status(api_status)
        case api_status&.to_s&.upcase
        when 'SUCCESS', 'ACCEPTED', 'CAPTURED'
          'completed'
        when 'CANCELLED', 'CANCELED'
          'cancelled'
        when 'FAILED', 'REFUSED', 'DECLINED'
          'failed'
        when 'PENDING', 'PROCESSING'
          'processing'
        else
          'unknown'
        end
      end

      def callback_url
        Rails.application.routes.url_helpers.payment_callback_url(host: base_host)
      end

      def cancel_url
        Rails.application.routes.url_helpers.payment_cancel_url(host: base_host)
      end

      def notify_url
        Rails.application.routes.url_helpers.payment_notify_url(host: base_host)
      end

      def base_host
        ENV.fetch('BASE_URL', 'http://localhost:3000')
      end
    end
  end
end

