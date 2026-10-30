# frozen_string_literal: true

module Admin
  # Articles de la boutique équipements (cf. GLOSSARY.md). Leurs coupes et
  # leurs coloris se gèrent depuis la fiche de l'article ; un article n'est
  # pas supprimé mais retiré de la vente.
  class ShopProductsController < BaseController
    before_action :require_admin!
    before_action :set_product, only: [ :edit, :update ]

    def index
      @catalog = Shop::Catalog.new(Shop::Product.ordered)
    end

    def new
      @product = Shop::Product.new(active: true)
    end

    def create
      @product = Shop::Product.new(product_params)
      return redirect_to(edit_admin_shop_product_path(@product), notice: "Article créé : ajoute ses coupes et ses coloris") if @product.save

      render :new, status: :unprocessable_content
    end

    def edit
      @sheet = ShopProductSheet.new(@product)
    end

    def update
      return redirect_to(edit_admin_shop_product_path(@product), notice: "Article mis à jour") if @product.update(product_params)

      @sheet = ShopProductSheet.new(@product)
      render :edit, status: :unprocessable_content
    end

    private

    def set_product
      @product = Shop::Product.find(params[:id])
    end

    def product_params
      params.require(:shop_product).permit(:name, :brand, :description, :marking, :position, :active)
    end
  end
end
