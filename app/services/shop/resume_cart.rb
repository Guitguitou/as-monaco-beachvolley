# frozen_string_literal: true

module Shop
  # Panier d'un membre pour une campagne. Une commande restée verrouillée
  # parce que son dernier paiement a échoué ou a été abandonné redevient un
  # panier modifiable ; tant qu'un paiement est en cours, elle reste fermée.
  class ResumeCart
    def initialize(user:, campaign:)
      @user = user
      @campaign = campaign
    end

    def call
      Order.cart_for(@user, @campaign) || reopen(Order.awaiting_payment_for(@user, @campaign))
    end

    private

    def reopen(order)
      return unless order && last_payment_given_up?(order)

      order.update!(status: :cart)
      order
    end

    def last_payment_given_up?(order)
      last = CreditPurchase.where(shop_order_id: order.id).order(:created_at, :id).last
      last.nil? || last.failed_status? || last.cancelled_status?
    end
  end
end
