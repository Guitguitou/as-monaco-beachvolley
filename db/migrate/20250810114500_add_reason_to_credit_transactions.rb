class AddReasonToCreditTransactions < ActiveRecord::Migration[8.0]
  def change
    add_column :credit_transactions, :reason, :string
  end
end
