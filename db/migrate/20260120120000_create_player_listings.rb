class CreatePlayerListings < ActiveRecord::Migration[7.2]
  def change
    create_table :player_listings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :session, null: true, foreign_key: true
      t.string :listing_type, null: false
      t.string :gender
      t.date :date
      t.time :starts_at
      t.time :ends_at
      t.string :status, null: false, default: "active"
      t.text :notes

      t.timestamps
    end

    add_index :player_listings, [:status, :listing_type, :date]
  end
end
