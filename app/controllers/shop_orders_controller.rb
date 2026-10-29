# frozen_string_literal: true

# Commandes d'équipements payées du membre, toutes campagnes confondues.
class ShopOrdersController < ApplicationController
  def index
    @orders = paid_orders.includes(:campaign).order(paid_at: :desc)
  end

  def show
    @order = paid_orders.find(params[:id])
    @lines = @order.lines.includes(:cut, color: { photo_attachment: :blob }).to_a
  end

  private

  def paid_orders = Shop::Order.paid_status.where(user: current_user)
end
