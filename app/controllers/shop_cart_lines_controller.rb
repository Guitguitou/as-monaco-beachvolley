# frozen_string_literal: true

# Lignes du panier : ajout depuis la fiche d'un article, changement de
# quantité et retrait depuis le panier. Le prix n'est jamais lu du formulaire.
class ShopCartLinesController < ShopBaseController
  before_action :require_open_campaign
  before_action :set_line, only: [ :update, :destroy ]

  def create
    cut = Shop::Cut.find(line_params[:cut_id])
    result = Shop::AddToCart.new(
      user: current_user, campaign: campaign, cut: cut, color: Shop::Color.find_by(id: line_params[:color_id]),
      size: line_params[:size], quantity: line_params[:quantity].presence || 1
    ).call
    return redirect_to(shop_cart_path, notice: "#{result.line.product_name} ajouté au panier") unless result.error

    redirect_to shop_product_path(cut.product_id), alert: result.error
  end

  def update
    return redirect_to(shop_cart_path) if @line.update(quantity: params.require(:quantity))

    redirect_to shop_cart_path, alert: @line.errors.full_messages.to_sentence
  end

  def destroy
    @line.destroy!
    redirect_to shop_cart_path, notice: "#{@line.product_name} retiré du panier"
  end

  private

  def set_line
    @line = cart ? cart.lines.find(params[:id]) : raise(ActiveRecord::RecordNotFound)
  end

  def line_params = params.require(:line).permit(:cut_id, :color_id, :size, :quantity)
end
