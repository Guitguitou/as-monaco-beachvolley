module Admin
  class PaymentsController < ApplicationController
    layout 'dashboard'
    before_action :authenticate_user!
    before_action :ensure_admin!

    def show
      @credit_purchases = current_user.credit_purchases.order(created_at: :desc).limit(10)
      @current_balance  = current_user.balance&.amount || 0
    end

    def buy_10_eur
      # 10 € = 1000 crédits
      @credit_purchase = CreditPurchase.create_pack_10_eur(user: current_user)

      ref          = @credit_purchase.sherlock_transaction_reference || "CP-#{@credit_purchase.id}-#{SecureRandom.hex(4)}"
      amount_cents = @credit_purchase.amount_cents
      currency     = @credit_purchase.currency || ENV.fetch("CURRENCY", "EUR")

      # Construction du formulaire auto-submit via la gateway réelle
      payment_html = Sherlock::CreatePayment.call(
        reference: ref,
        amount_cents: amount_cents,
        currency: currency,
        return_urls: {
          success: Rails.application.routes.url_helpers.success_checkout_url(host: ENV.fetch("APP_HOST")),
          cancel:  Rails.application.routes.url_helpers.cancel_checkout_url(host: ENV.fetch("APP_HOST")),
          auto:    Rails.application.routes.url_helpers.webhooks_sherlock_url(host: ENV.fetch("APP_HOST"))
        },
        customer: { id: current_user.id, email: current_user.email }
      )

      # On enregistre la référence et passe à pending
      @credit_purchase.update!(sherlock_transaction_reference: ref, status: :pending)

      # ⚠️ IMPORTANT : on RENVOIE le HTML (form POST auto-submit), pas un redirect
      render html: payment_html.html_safe, layout: false
    rescue StandardError => e
      Rails.logger.error("Payment creation failed: #{e.class} - #{e.message}")
      redirect_to admin_payments_path, alert: "Erreur lors de la création du paiement : #{e.message}"
    end

    private

    def ensure_admin!
      redirect_to(root_path, alert: "Accès interdit") unless current_user.admin?
    end
  end
end
