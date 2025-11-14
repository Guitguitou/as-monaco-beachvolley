class AddFinancialManagerToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :financial_manager, :boolean, default: false, null: false
    add_index :users, :financial_manager
  end
end
