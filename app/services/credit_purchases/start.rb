# frozen_string_literal: true

module CreditPurchases
  # Ouvre l'achat d'un pack, en attente de paiement, et prépare la demande
  # envoyée à Sherlock's. Les stages et licences ne créditent rien.
  class Start
    def initialize(user:, pack:)
      @user = user
      @pack = pack
    end

    # Renvoie [achat, demande de paiement].
    def call
      purchase = @user.credit_purchases.create!(
        pack: @pack, amount_cents: @pack.amount_cents, currency: "EUR", credits: @pack.credits || 0, status: :pending
      )
      [ purchase, Sherlock::CreatePayment.new(purchase).call ]
    end
  end
end
