module Sherlock
  class FakeGateway < Gateway
    # Gateway de paiement fictive pour le développement
    # Redirige automatiquement vers la page de succès
    
    def create_payment(reference:, amount_cents:, currency:, return_urls:, customer:)
      # En mode fake, on redirige directement vers success
      # avec des paramètres simulés
      success_url = return_urls[:success]
      params = {
        reference: reference,
        amount: amount_cents,
        status: 'paid',
        fake: 'true'
      }
      
      "#{success_url}?#{params.to_query}"
    end
  end
end

