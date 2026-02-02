class CreatePlayerRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :player_requests do |t|
      t.references :player_listing, null: false, foreign_key: true
      t.references :from_user, null: false, foreign_key: { to_table: :users }
      t.references :to_user, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "pending"
      t.text :message

      t.timestamps
    end

    add_index :player_requests, [:to_user_id, :status]
  end
end
