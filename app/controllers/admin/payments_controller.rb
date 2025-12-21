# frozen_string_literal: true

module Admin
  class PaymentsController < ApplicationController
    layout "dashboard"
    before_action :authenticate_user!
    before_action :ensure_admin!

    def show
      @credit_purchases = current_user.credit_purchases.order(created_at: :desc).limit(10)
      @current_balance  = current_user.balance&.amount || 0
    end

    def buy_10_eur
      # 10 € = 1000 crédits
      @credit_purchase = CreditPurchase.create_pack_10_eur(user: current_user)

      # Construction du formulaire auto-submit via la gateway réelle
      payment_html = Sherlock::CreatePayment.new(@credit_purchase).call

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
