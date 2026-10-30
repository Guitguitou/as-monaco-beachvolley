# frozen_string_literal: true

# Où renvoyer le membre au retour de la page de paiement d'une commande
# d'équipements : sa commande une fois payée, sinon son panier.
class ShopCheckoutReturn
  def initialize(purchase, routes:)
    @purchase = purchase
    @routes = routes
  end

  # Arguments de redirect_to : [chemin, flash].
  def destination
    order = @purchase.shop_order
    return [ @routes.shop_order_path(order), { notice: "Paiement accepté : ta commande est enregistrée." } ] if @purchase.paid_status?
    return [ @routes.shop_cart_path, {} ] if @purchase.pending_status?

    [ @routes.shop_cart_path, { alert: "Le paiement n'a pas abouti : ton panier est toujours là, tu peux réessayer." } ]
  end
end
