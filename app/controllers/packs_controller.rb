class PacksController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index, :buy ]

  def index
    # Connecté : CanCanCan filtre selon les permissions
    # Non connecté : uniquement les packs marqués "public" par l’admin
    packs = Pack.active.ordered.select { |pack| user_signed_in? ? can?(:read, pack) : pack.public? }
    @credits_packs, @licence_packs, @stage_packs, @inscription_tournoi_packs, @equipements_packs =
      %w[credits licence stage inscription_tournoi equipements].map { |type| packs.select { |pack| pack.pack_type == type } }

    # Afficher la notice si user non activé
    @show_activation_notice = user_signed_in? && !current_user.activated?
    @current_balance = current_user&.balance&.amount || 0
  end

  def buy
    @pack = Pack.find(params[:id])
    return redirect_to(packs_path, alert: "Ce pack n'est plus disponible") unless @pack.active?

    # Vérification des permissions CanCanCan ; hors connexion, seuls les packs
    # "public" sont achetables.
    if user_signed_in?
      authorize! :buy, @pack
    elsif !@pack.public?
      return redirect_to(new_user_session_path, alert: "Connecte-toi pour acheter ce pack.")
    end

    buyer = user_signed_in? ? current_user : ensure_guest_user!
    return if performed? # ensure_guest_user! peut render/redirect

    # Page de transition aux couleurs du club, qui poste vers Sherlock's.
    @credit_purchase, @payment_request = CreditPurchases::Start.new(user: buyer, pack: @pack).call
    render :redirect
  rescue StandardError => e
    Rails.logger.error("Payment creation failed: #{e.message}")
    redirect_to packs_path, alert: "Erreur lors de la création du paiement: #{e.message}"
  end

  # CanCanCan gère les permissions via app/models/ability.rb
  private

  def ensure_guest_user!
    if params[:guest].blank?
      render :guest_info, status: :ok
      return
    end

    result = Users::GuestSignup.new(**guest_identity_params.to_h.symbolize_keys).call
    return result.user if result.user

    flash.now[:alert] = result.error
    render :guest_info, status: :unprocessable_entity
  end

  def guest_identity_params
    params.require(:guest).permit(:email, :first_name, :last_name)
  end
end
