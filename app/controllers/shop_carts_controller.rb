# frozen_string_literal: true

# Panier du membre pour la campagne ouverte.
class ShopCartsController < ShopBaseController
  before_action :require_open_campaign

  def show
    @lines = cart ? cart.lines.includes(color: { photo_attachment: :blob }).to_a : []
  end
end
