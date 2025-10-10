# Service métier pour gérer les paiements LCL
# Délègue les appels API au module Lcl::Api
class LclPaymentService
  attr_reader :payment, :lcl_client

  def initialize(payment)
    @payment = payment
    @lcl_client = Lcl.client
  end

  # Initie un nouveau paiement
  # @return [Hash] { success: Boolean, payment_url: String, error: String }
  def initiate_payment
    result = lcl_client.payment.create(payment)

    if result[:success]
      payment.update!(
        status: 'processing',
        sherlock_transaction_id: result[:transaction_id]
      )
    else
      payment.update!(status: 'failed')
    end

    result
  rescue Lcl::Client::ConfigurationError => e
    Rails.logger.error "LCL configuration error: #{e.message}"
    { success: false, error: 'Configuration LCL manquante' }
  rescue StandardError => e
    Rails.logger.error "Erreur lors de l'initiation du paiement: #{e.message}"
    payment.update!(status: 'failed')
    { success: false, error: e.message }
  end

  # Traite le callback de retour de paiement
  # @param params [Hash] Les paramètres du callback
  # @return [Hash] { success: Boolean, status: String, error: String }
  def handle_callback(params)
    result = lcl_client.payment.handle_callback(params)

    if result[:success]
      update_payment_status(result[:status])
      
      # Stocker la réponse brute pour audit
      payment.update!(sherlock_response: result[:raw_response]) if result[:raw_response]
    end

    result
  rescue StandardError => e
    Rails.logger.error "Erreur lors du traitement du callback: #{e.message}"
    { success: false, error: e.message }
  end

  # Rembourse un paiement
  # @param amount_cents [Integer] Montant à rembourser (optionnel, par défaut le montant total)
  # @return [Hash] { success: Boolean, refund_id: String, error: String }
  def refund(amount_cents: nil)
    result = lcl_client.payment.refund(payment, amount_cents: amount_cents)

    if result[:success]
      payment.update!(
        status: 'refunded',
        sherlock_response: { refund_id: result[:refund_id], amount: result[:amount_refunded] }
      )
    end

    result
  rescue StandardError => e
    Rails.logger.error "Erreur lors du remboursement: #{e.message}"
    { success: false, error: e.message }
  end

  private

  # Met à jour le statut du paiement selon le résultat du callback
  def update_payment_status(status)
    case status
    when 'completed'
      payment.complete!
    when 'cancelled'
      payment.cancel!
    when 'failed'
      payment.fail!
    when 'processing'
      payment.update!(status: 'processing')
    end
  end
end
