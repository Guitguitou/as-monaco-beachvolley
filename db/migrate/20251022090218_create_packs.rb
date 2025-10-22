class CreatePacks < ActiveRecord::Migration[8.0]
  def change
    create_table :packs do |t|
      t.string :name, null: false
      t.text :description
      t.string :pack_type, null: false, default: 'credits'
      t.integer :amount_cents, null: false
      t.integer :credits
      t.boolean :active, default: true, null: false
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :packs, :pack_type
    add_index :packs, :active
    add_index :packs, :position
  end
end
