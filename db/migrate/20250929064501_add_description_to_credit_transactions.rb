class AddDescriptionToCreditTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :credit_transactions, :description, :text
  end
end
