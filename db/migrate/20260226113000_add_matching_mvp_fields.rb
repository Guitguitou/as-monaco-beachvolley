class AddMatchingMvpFields < ActiveRecord::Migration[8.0]
  def change
    add_column :sessions, :open_for_matching, :boolean, null: false, default: false
    add_index :sessions, [:open_for_matching, :start_at]

    add_column :users, :player_suggestions_push_enabled, :boolean, null: false, default: true

    create_table :player_suggestion_notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :event_type, null: false
      t.string :fingerprint, null: false

      t.timestamps
    end

    add_index :player_suggestion_notifications, [:user_id, :fingerprint], name: "index_player_suggestion_notifications_on_user_and_fingerprint"
    add_index :player_suggestion_notifications, [:user_id, :created_at], name: "index_player_suggestion_notifications_on_user_and_created_at"
  end
end
