class AddStatusToRegistrations < ActiveRecord::Migration[8.0]
  def change
    add_column :registrations, :status, :integer, null: false, default: 0
    add_index :registrations, [:session_id, :status, :created_at], name: "index_registrations_on_session_status_created_at"
  end
end
