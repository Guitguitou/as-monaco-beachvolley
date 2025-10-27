class PacksController < ApplicationController
  before_action :authenticate_user!, except: [:index, :buy]
  before_action :authenticate_user_for_credits!, only: [:buy]

  def index
    @credits_packs = Pack.active.credits_packs.ordered
    @licence_packs = Pack.active.licence_packs.ordered
    @stage_packs = Pack.active.stage_packs.ordered.includes(:stage)
    @current_balance = current_user&.balance&.amount || 0
  end

  def buy
    @pack = Pack.find(params[:id])
    
    unless @pack.active?
      redirect_to packs_path, alert: "Ce pack n'est plus disponible"
      return
    end

    # Vérifier si l'utilisateur est connecté pour les packs de crédits
    if @pack.pack_type_credits? && !user_signed_in?
      redirect_to new_user_session_path, alert: "Vous devez être connecté pour acheter des crédits"
      return
    end

    # Créer le CreditPurchase avec le pack
    if user_signed_in?
      @credit_purchase = current_user.credit_purchases.create!(
        pack: @pack,
        amount_cents: @pack.amount_cents,
        currency: 'EUR',
        credits: @pack.credits || 0, # 0 pour les stages et licences
        status: :pending
      )
    else
      # Pour les utilisateurs non connectés, créer un achat temporaire
      @credit_purchase = CreditPurchase.create!(
        user: nil,
        pack: @pack,
        amount_cents: @pack.amount_cents,
        currency: 'EUR',
        credits: @pack.credits || 0,
        status: :pending
      )
    end

    # Générer le formulaire HTML de redirection vers la gateway
    payment_html = Sherlock::CreatePayment.new(@credit_purchase).call

    # Rendre le formulaire HTML qui va auto-submit vers Sherlock
    render html: payment_html.html_safe, layout: false, content_type: "text/html"
  rescue StandardError => e
    Rails.logger.error("Payment creation failed: #{e.message}")
    redirect_to packs_path, alert: "Erreur lors de la création du paiement: #{e.message}"
  end

  private

  def authenticate_user_for_credits!
    # Cette méthode sera appelée seulement pour les packs de crédits
    # Les stages et licences peuvent être achetés sans connexion
  end
end
