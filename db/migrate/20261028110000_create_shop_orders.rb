# frozen_string_literal: true

# Campagnes de commande groupée et commandes de la boutique équipements
# (cf. GLOSSARY.md). Une ligne garde le libellé et le prix au moment de
# l'ajout : modifier le catalogue ne réécrit pas les commandes passées.
class CreateShopOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :shop_campaigns do |t|
      t.string :name, null: false
      t.date :opens_on, null: false
      t.date :closes_on, null: false
      t.string :status, null: false, default: "draft"
      t.text :welcome_message
      t.boolean :allow_edits, null: false, default: true
      t.timestamps
    end

    create_table :shop_orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :campaign, null: false, foreign_key: { to_table: :shop_campaigns }
      t.string :status, null: false, default: "cart"
      t.string :number
      t.string :team
      t.datetime :paid_at
      t.timestamps
      t.index :number, unique: true, where: "number IS NOT NULL"
      t.index %i[user_id campaign_id], unique: true, where: "status = 'cart'", name: "index_shop_orders_one_cart_per_campaign"
    end

    create_table :shop_order_lines do |t|
      t.references :order, null: false, foreign_key: { to_table: :shop_orders, on_delete: :cascade }
      t.references :product, null: false, foreign_key: { to_table: :shop_products }
      t.references :cut, foreign_key: { to_table: :shop_cuts, on_delete: :nullify }
      t.references :color, foreign_key: { to_table: :shop_colors, on_delete: :nullify }
      t.string :product_name, null: false
      t.string :cut_label, null: false
      t.string :color_name, null: false
      t.string :size, null: false
      t.integer :quantity, null: false
      t.integer :unit_price_cents, null: false
      t.timestamps
    end
  end
end
