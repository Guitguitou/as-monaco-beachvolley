# app/services/sherlock/fake_gateway.rb
module Sherlock
  class FakeGateway < Gateway
    # On simule la redirection vers la page banque en renvoyant un HTML
    # qui redirige directement vers le success (pour les tests manuels).
    def create_payment(reference:, amount_cents:, currency:, return_urls:, customer:)
      <<~HTML
        <html>
          <head><meta charset="utf-8"><title>Fake Payment</title></head>
          <body>
            <p>FakeGateway: redirection vers la réussite immédiate…</p>
            <script>
              // En staging/dev, on simule un retour utilisateur :
              window.location = "#{return_urls[:success]}?transactionReference=#{ERB::Util.url_encode(reference)}&responseCode=00&transactionStatus=ACCEPTED";
            </script>
          </body>
        </html>
      HTML
    end
  end
end
