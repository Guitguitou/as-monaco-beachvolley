class MakeCreditTransactionsSessionNullable < ActiveRecord::Migration[8.0]
  def change
    change_column_null :credit_transactions, :session_id, true
  end
end
