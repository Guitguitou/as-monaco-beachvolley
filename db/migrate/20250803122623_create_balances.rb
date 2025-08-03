class CreateBalances < ActiveRecord::Migration[8.0]
  def change
    create_table :balances do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :amount

      t.timestamps
    end
  end
end
