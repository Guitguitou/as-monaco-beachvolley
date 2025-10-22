class PacksController < ApplicationController
  before_action :authenticate_user!

  def index
    @packs = Pack.active.credits_packs.ordered
    @current_balance = current_user.balance&.amount || 0
  end

  def buy
    @pack = Pack.find(params[:id])
    
    unless @pack.active?
      redirect_to packs_path, alert: "Ce pack n'est plus disponible"
      return
    end

    # Créer le CreditPurchase avec le pack
    @credit_purchase = current_user.credit_purchases.create!(
      pack: @pack,
      amount_cents: @pack.amount_cents,
      currency: 'EUR',
      credits: @pack.credits || 0,
      status: :pending
    )

    # Générer l'URL de paiement via la gateway
    payment_url = Sherlock::CreatePayment.new(@credit_purchase).call

    # Rediriger vers la page de paiement
    redirect_to payment_url, allow_other_host: true
  rescue StandardError => e
    Rails.logger.error("Payment creation failed: #{e.message}")
    redirect_to packs_path, alert: "Erreur lors de la création du paiement: #{e.message}"
  end
end
