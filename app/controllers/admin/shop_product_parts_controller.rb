# frozen_string_literal: true

module Admin
  # Socle des coupes et des coloris d'un article : chacun s'ajoute, se modifie
  # ou se supprime depuis la fiche de l'article, qui est toujours réaffichée.
  class ShopProductPartsController < BaseController
    before_action :require_admin!
    before_action :set_product
    before_action :set_part, only: [ :update, :destroy ]

    def create
      save_and_return(part_class.new(part_params.merge(product: @product)), notices.fetch(:create))
    end

    def update
      @part.assign_attributes(part_params)
      save_and_return(@part, notices.fetch(:update))
    end

    def destroy
      @part.destroy!
      redirect_to sheet_path, notice: notices.fetch(:destroy)
    end

    private

    def save_and_return(part, notice)
      return redirect_to(sheet_path, notice: notice) if part.save

      redirect_to sheet_path, alert: part.errors.full_messages.to_sentence
    end

    def set_product
      @product = Shop::Product.find(params[:shop_product_id])
    end

    def set_part
      @part = part_class.of(@product).find(params[:id])
    end

    def sheet_path = edit_admin_shop_product_path(@product, anchor: anchor)

    def part_params = params.require(part_class.model_name.param_key).permit(*permitted)
  end
end
