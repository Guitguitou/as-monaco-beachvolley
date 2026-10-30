# frozen_string_literal: true

# Catalogue de la boutique équipements et fiche d'un article, d'où le membre
# ajoute au panier coupe, coloris et taille.
class ShopProductsController < ShopBaseController
  before_action :require_open_campaign, only: :show

  def index
    @entries = campaign ? Shop::Catalog.new(Shop::Product.on_sale.ordered).entries.select { |entry| sellable?(entry) } : []
  end

  def show
    @page = ShopProductPage.new(Shop::Product.on_sale.find(params[:id]))
    redirect_to shop_products_path, alert: "Cet article n'est pas encore disponible." unless @page.sellable?
  end

  private

  def sellable?(entry) = entry.cuts.any? && entry.colors.any?
end
