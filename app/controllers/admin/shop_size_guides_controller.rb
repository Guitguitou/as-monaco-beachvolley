# frozen_string_literal: true

module Admin
  # Guides des tailles (cf. GLOSSARY.md), saisis une fois par marque et
  # réutilisés par les coupes. Supprimer un guide le détache de ses coupes.
  class ShopSizeGuidesController < BaseController
    before_action :require_admin!
    before_action :set_guide, only: [ :edit, :update, :destroy ]

    def index
      @guides = Shop::SizeGuide.ordered
      @usage = Shop::Cut.where.not(size_guide_id: nil).group(:size_guide_id).count
    end

    def new
      @guide = Shop::SizeGuide.new
    end

    def create
      @guide = Shop::SizeGuide.new(guide_params)
      redirect_or_render(@guide.save, :new, to: admin_shop_size_guides_path, notice: "Guide des tailles créé")
    end

    def edit; end

    def update
      redirect_or_render(@guide.update(guide_params), :edit, to: admin_shop_size_guides_path, notice: "Guide des tailles mis à jour")
    end

    def destroy
      @guide.destroy!
      redirect_to admin_shop_size_guides_path, notice: "Guide des tailles supprimé"
    end

    private

    def set_guide
      @guide = Shop::SizeGuide.find(params[:id])
    end

    def guide_params
      params.require(:shop_size_guide).permit(:name, :measure_label, :rows_text)
    end
  end
end
