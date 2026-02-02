class CreatePlayerListingLevels < ActiveRecord::Migration[7.2]
  def change
    create_table :player_listing_levels do |t|
      t.references :player_listing, null: false, foreign_key: true
      t.references :level, null: false, foreign_key: true

      t.timestamps
    end

    add_index :player_listing_levels, [:player_listing_id, :level_id], unique: true
  end
end
