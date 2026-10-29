# frozen_string_literal: true

module Admin
  # Commandes d'une campagne : payées, à remettre au membre, et paniers non
  # aboutis à relancer par e-mail.
  class ShopOrdersController < BaseController
    before_action :require_admin!
    before_action :set_order, only: [ :hand_over, :remind ]

    def index
      @choice = ShopCampaignChoice.new(params[:campaign_id])
      @board = ShopOrdersBoard.new(campaign: @choice.campaign, filter: params[:filter]) if @choice.campaign
    end

    def hand_over
      @order.toggle_handed_over! if @order.paid_status?
      redirect_back_to_orders(notice: @order.handed_over? ? "#{@order.number} remise au membre" : "#{@order.number} à remettre")
    end

    def remind
      ShopMailer.unfinished_order(@order).deliver_later unless @order.paid_status?
      redirect_back_to_orders(notice: "Relance envoyée à #{@order.user.full_name}")
    end

    private

    def set_order
      @order = Shop::Order.find(params[:id])
    end

    def redirect_back_to_orders(notice:)
      redirect_to admin_shop_orders_path(campaign_id: @order.campaign_id, filter: params[:filter]), notice: notice
    end
  end
end
