# frozen_string_literal: true

# Correction de taille sur une ligne d'une commande payée du membre.
class ShopOrderLinesController < ApplicationController
  def update
    line = Shop::OrderLine.where(order_id: Shop::Order.paid_status.where(user: current_user).select(:id)).find(params[:id])
    error = Shop::ChangeLineSize.new(line: line, size: params.require(:size)).call

    redirect_to shop_order_path(line.order_id), **(error ? { alert: error } : { notice: "Taille modifiée : #{line.size}" })
  end
end
