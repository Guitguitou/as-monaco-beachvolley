# frozen_string_literal: true

# Socle de la boutique équipements côté membre : la campagne ouverte aux
# commandes, s'il y en a une, et le panier du membre pour cette campagne
# (rouvert si son dernier paiement a échoué ou a été abandonné).
class ShopBaseController < ApplicationController
  helper_method :campaign, :cart

  private

  def campaign = @campaign ||= Shop::Campaign.for_members

  def cart
    return @cart if defined?(@cart)

    @cart = campaign && Shop::ResumeCart.new(user: current_user, campaign: campaign).call
  end

  def require_open_campaign
    redirect_to shop_products_path, alert: "Les commandes d'équipements sont fermées." unless campaign
  end
end
