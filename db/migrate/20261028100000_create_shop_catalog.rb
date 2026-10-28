# frozen_string_literal: true

# Catalogue de la boutique équipements (cf. GLOSSARY.md) : articles, coupes
# (prix et tailles), coloris (photo) et guides des tailles.
class CreateShopCatalog < ActiveRecord::Migration[8.1]
  def change
    create_table :shop_size_guides do |t|
      t.string :name, null: false
      t.string :measure_label, null: false
      t.jsonb :rows, null: false, default: []
      t.timestamps
    end

    create_table :shop_products do |t|
      t.string :name, null: false
      t.string :brand, null: false
      t.string :description
      t.string :marking
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    create_table :shop_cuts do |t|
      t.references :product, null: false, foreign_key: { to_table: :shop_products }
      t.references :size_guide, foreign_key: { to_table: :shop_size_guides, on_delete: :nullify }
      t.string :label, null: false
      t.integer :price_cents, null: false
      t.string :sizes, array: true, null: false, default: []
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :shop_colors do |t|
      t.references :product, null: false, foreign_key: { to_table: :shop_products }
      t.string :name, null: false
      t.string :hex, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
  end
end
