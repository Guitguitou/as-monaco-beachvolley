class CreateCreditPackages < ActiveRecord::Migration[8.0]
  def change
    create_table :credit_packages do |t|
      t.string :name
      t.text :description
      t.integer :credits
      t.integer :price_cents
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
