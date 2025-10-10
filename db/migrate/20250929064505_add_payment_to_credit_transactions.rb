class AddPaymentToCreditTransactions < ActiveRecord::Migration[8.0]
  def change
    add_reference :credit_transactions, :payment, null: true, foreign_key: true
  end
end
