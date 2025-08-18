class AddLicenseTypeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :license_type, :string
    add_index :users, :license_type
  end
end
