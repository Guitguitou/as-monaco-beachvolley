# frozen_string_literal: true

# Panier du membre pour la campagne ouverte, sa validation vers la page de
# paiement, et l'abandon d'un paiement resté en cours.
class ShopCartsController < ShopBaseController
  before_action :require_open_campaign

  def show
    @lines = cart ? cart.lines.includes(color: { photo_attachment: :blob }).to_a : []
    @awaiting = Shop::Order.awaiting_payment_for(current_user, campaign) unless cart
  end

  def checkout
    return redirect_to(shop_cart_path, alert: "Ton panier est vide.") unless cart

    result = Shop::Checkout.new(order: cart).call
    return redirect_to(shop_cart_path, alert: result.error) if result.error

    @credit_purchase = result.purchase
    @payment_request = result.payment_request
    render "packs/redirect", locals: { label: "Commande d'équipements" }
  end

  def cancel_payment
    order = Shop::Order.awaiting_payment_for(current_user, campaign)
    CreditPurchase.pending_status.where(shop_order_id: order.id).find_each(&:mark_as_abandoned!) if order
    redirect_to shop_cart_path, notice: "Paiement annulé : tu peux modifier ton panier."
  end
end
