class MakeCreditTransactionsSessionNullable < ActiveRecord::Migration[8.0]
  def change
    change_column_null :credit_transactions, :session_id, true
    # Ensure FK nullifies on session deletion for historical transactions
    remove_foreign_key :credit_transactions, :sessions rescue nil
    add_foreign_key :credit_transactions, :sessions, on_delete: :nullify
  end
end
