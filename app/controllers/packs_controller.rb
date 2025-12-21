# frozen_string_literal: true

class PacksController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :buy ]

  def index
    # Charger tous les packs actifs
    all_packs = Pack.active.ordered

    # CanCanCan filtre selon les permissions (activated? pour credits/stages)
    if user_signed_in?
      accessible_packs = all_packs.select { |pack| can?(:read, pack) }
    else
      # Utilisateurs non connectés : tous les packs visibles (achat redirige vers login sauf licences)
      accessible_packs = all_packs
    end

    # Regrouper par type
    @credits_packs = accessible_packs.select(&:pack_type_credits?)
    @licence_packs = accessible_packs.select(&:pack_type_licence?)
    @stage_packs = accessible_packs.select(&:pack_type_stage?)

    # Afficher la notice si user non activé
    @show_activation_notice = user_signed_in? && !current_user.activated?
    @current_balance = current_user&.balance&.amount || 0
  end

  def buy
    @pack = Pack.find(params[:id])
    authorize! :buy, @pack if user_signed_in?

    service = PackPurchaseService.new(@pack, current_user)
    @credit_purchase = service.call

    payment_html = Sherlock::CreatePayment.new(@credit_purchase).call
    render html: payment_html.html_safe, layout: false, content_type: "text/html"
  rescue StandardError => e
    Rails.logger.error("Payment creation failed: #{e.message}")
    redirect_to packs_path, alert: "Erreur lors de la création du paiement: #{e.message}"
  end

  # CanCanCan gère les permissions via app/models/ability.rb
end
