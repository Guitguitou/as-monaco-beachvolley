class AddPackToCreditPurchases < ActiveRecord::Migration[8.0]
  def change
    add_reference :credit_purchases, :pack, null: true, foreign_key: true, index: true
  end
end
