# frozen_string_literal: true

# Le paiement d'une commande d'équipements passe par un achat Sherlock's,
# comme celui d'un pack : l'achat porte la commande qu'il règle.
class AddShopOrderToCreditPurchases < ActiveRecord::Migration[8.1]
  def change
    add_reference :credit_purchases, :shop_order, foreign_key: true
  end
end
