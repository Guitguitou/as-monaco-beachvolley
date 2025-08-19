class AddRegistrationOpensAtToSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :sessions, :registration_opens_at, :datetime
    add_index :sessions, :registration_opens_at
  end
end
