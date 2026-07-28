class CreateAnnonces < ActiveRecord::Migration[8.0]
  def change
    create_table :annonces do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :status, null: false, default: 0
      t.integer :min_players, null: false, default: 4
      t.references :session, null: true, foreign_key: true

      t.timestamps
    end

    create_table :annonce_slots do |t|
      t.references :annonce, null: false, foreign_key: true
      t.datetime :start_at, null: false
      t.datetime :end_at, null: false

      t.timestamps
    end

    create_table :annonce_availabilities do |t|
      t.references :annonce_slot, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :annonce_availabilities, [ :annonce_slot_id, :user_id ], unique: true, name: "index_annonce_availabilities_on_slot_and_user"

    create_table :annonce_levels do |t|
      t.references :annonce, null: false, foreign_key: true
      t.references :level, null: false, foreign_key: true

      t.timestamps
    end
    add_index :annonce_levels, [ :annonce_id, :level_id ], unique: true
  end
end
