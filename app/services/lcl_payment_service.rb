class LclPaymentService
  # Configuration LCL/Sherlock
  SHERLOCK_BASE_URL = Rails.env.production? ? 'https://secure.lcl.fr' : 'https://recette.secure.lcl.fr'
  
  def initialize(payment)
    @payment = payment
    @merchant_id = Rails.application.credentials.lcl&.merchant_id
    @certificate_path = Rails.application.credentials.lcl&.certificate_path
    @private_key_path = Rails.application.credentials.lcl&.private_key_path
  end

  def initiate_payment
    return { success: false, error: 'Configuration LCL manquante' } unless configured?

    begin
      # Générer l'URL de paiement LCL/Sherlock
      payment_url = generate_payment_url
      
      # Mettre à jour le statut du paiement
      @payment.update!(
        status: 'processing',
        sherlock_transaction_id: generate_transaction_id
      )

      { success: true, payment_url: payment_url }
    rescue => e
      Rails.logger.error "Erreur lors de l'initiation du paiement LCL: #{e.message}"
      @payment.update!(status: 'failed')
      { success: false, error: e.message }
    end
  end

  def handle_callback(params)
    # Vérifier la signature de la réponse LCL
    return { success: false, error: 'Signature invalide' } unless valid_signature?(params)

    case params[:status]
    when 'SUCCESS'
      @payment.complete!
      { success: true, status: 'completed' }
    when 'CANCELLED'
      @payment.cancel!
      { success: true, status: 'cancelled' }
    when 'FAILED'
      @payment.fail!
      { success: true, status: 'failed' }
    else
      { success: false, error: 'Statut inconnu' }
    end
  end

  private

  def configured?
    @merchant_id.present? && @certificate_path.present? && @private_key_path.present?
  end

  def generate_payment_url
    # Paramètres de base pour LCL/Sherlock
    base_params = {
      merchant_id: @merchant_id,
      amount: @payment.amount_cents,
      currency: 'EUR',
      order_id: @payment.id,
      customer_email: @payment.user.email,
      customer_name: @payment.user.full_name,
      return_url: Rails.application.routes.url_helpers.payment_callback_url,
      cancel_url: Rails.application.routes.url_helpers.payment_cancel_url,
      notify_url: Rails.application.routes.url_helpers.payment_notify_url
    }

    # Ajouter la signature
    signature = generate_signature(base_params)
    base_params[:signature] = signature

    # Construire l'URL
    "#{SHERLOCK_BASE_URL}/payment/init?#{base_params.to_query}"
  end

  def generate_transaction_id
    "PAY_#{@payment.id}_#{Time.current.to_i}"
  end

  def generate_signature(params)
    # Implémentation de la signature selon la documentation LCL/Sherlock
    # Cette méthode doit être adaptée selon la documentation fournie
    sorted_params = params.sort.to_h
    string_to_sign = sorted_params.map { |k, v| "#{k}=#{v}" }.join('&')
    
    # Utiliser la clé privée pour signer
    private_key = OpenSSL::PKey::RSA.new(File.read(@private_key_path))
    signature = private_key.sign(OpenSSL::Digest::SHA256.new, string_to_sign)
    Base64.encode64(signature).strip
  end

  def valid_signature?(params)
    # Vérifier la signature de la réponse LCL
    # Cette méthode doit être adaptée selon la documentation fournie
    return false unless params[:signature].present?

    # Extraire la signature reçue
    received_signature = params.delete(:signature)
    
    # Recalculer la signature
    expected_signature = generate_signature(params)
    
    # Comparer les signatures
    received_signature == expected_signature
  end
end
