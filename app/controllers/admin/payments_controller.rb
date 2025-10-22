module Admin
  class PaymentsController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_admin!

    def show
      @credit_purchases = current_user.credit_purchases.order(created_at: :desc).limit(10)
      @current_balance = current_user.balance&.amount || 0
    end

    def buy_10_eur
      # Créer le CreditPurchase pour 10 EUR = 1000 crédits
      @credit_purchase = CreditPurchase.create_pack_10_eur(user: current_user)

      # Générer l'URL de paiement via la gateway
      payment_url = Sherlock::CreatePayment.new(@credit_purchase).call

      # Rediriger vers la page de paiement
      redirect_to payment_url, allow_other_host: true
    rescue StandardError => e
      Rails.logger.error("Payment creation failed: #{e.message}")
      redirect_to admin_payments_path, alert: "Erreur lors de la création du paiement: #{e.message}"
    end

    private

    def ensure_admin!
      unless current_user.admin?
        redirect_to root_path, alert: "Accès interdit"
      end
    end
  end
end

