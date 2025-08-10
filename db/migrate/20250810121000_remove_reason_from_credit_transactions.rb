class RemoveReasonFromCreditTransactions < ActiveRecord::Migration[8.0]
  def change
    remove_column :credit_transactions, :reason, :string
  end
end
