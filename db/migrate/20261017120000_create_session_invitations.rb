class CreateSessionInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :session_invitations do |t|
      t.references :session, null: false, foreign_key: { on_delete: :cascade }
      t.references :inviter, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :invitee, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.timestamps
    end

    add_index :session_invitations, [ :session_id, :invitee_id ], unique: true
  end
end
