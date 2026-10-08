class CreateTournaments < ActiveRecord::Migration[8.0]
  def change
    create_table :tournaments do |t|
      t.string :title, null: false
      t.text :description
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.string :level, null: false
      t.integer :points
      t.integer :teams_count
      t.string :location
      t.string :registration_link
      t.integer :price_cents, null: false
      t.integer :terrains, array: true, default: [], null: false
      t.bigint :image_order, array: true, default: [], null: false
      t.timestamps
    end
    add_index :tournaments, :starts_on

    add_reference :packs, :tournament, foreign_key: true, index: { unique: true }
    add_reference :sessions, :tournament, foreign_key: true
  end
end
