class CreateTerrainClosures < ActiveRecord::Migration[8.0]
  def change
    create_table :terrain_closures do |t|
      t.string :terrain
      t.date :starts_on
      t.date :ends_on
      t.text :reason

      t.timestamps
    end

    add_index :terrain_closures, :terrain
    add_index :terrain_closures, [:starts_on, :ends_on]
  end
end
