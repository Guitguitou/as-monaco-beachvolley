class PacksController < ApplicationController
  before_action :authenticate_user!, except: [:index, :buy]

  def index
    # Charger tous les packs actifs
    all_packs = Pack.active.ordered
    
    # Connecté : CanCanCan filtre selon les permissions
    # Non connecté : uniquement les packs marqués "public" par l’admin
    if user_signed_in?
      accessible_packs = all_packs.select { |pack| can?(:read, pack) }
    else
      accessible_packs = all_packs.select(&:public?)
    end
    
    # Regrouper par type
    @credits_packs = accessible_packs.select(&:pack_type_credits?)
    @licence_packs = accessible_packs.select(&:pack_type_licence?)
    @stage_packs = accessible_packs.select(&:pack_type_stage?)
    @inscription_tournoi_packs = accessible_packs.select(&:pack_type_inscription_tournoi?)
    @equipements_packs = accessible_packs.select(&:pack_type_equipements?)
    
    # Afficher la notice si user non activé
    @show_activation_notice = user_signed_in? && !current_user.activated?
    @current_balance = current_user&.balance&.amount || 0
  end

  def buy
    @pack = Pack.find(params[:id])
    
    unless @pack.active?
      redirect_to packs_path, alert: "Ce pack n'est plus disponible"
      return
    end

    # Vérification des permissions CanCanCan
    if user_signed_in?
      authorize! :buy, @pack
    elsif !@pack.public?
      # Hors connexion : seuls les packs "public" sont achetables
      redirect_to new_user_session_path, alert: "Vous devez être connecté pour acheter ce pack"
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

  # CanCanCan gère les permissions via app/models/ability.rb
end
