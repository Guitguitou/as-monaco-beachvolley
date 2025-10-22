class CreateCreditPurchases < ActiveRecord::Migration[8.0]
  def change
    create_table :credit_purchases do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: 'EUR'
      t.integer :credits, null: false
      t.string :status, null: false, default: 'pending'
      t.string :sherlock_transaction_reference
      t.jsonb :sherlock_fields, default: {}
      t.datetime :paid_at
      t.datetime :failed_at

      t.timestamps
    end

    add_index :credit_purchases, :status
    add_index :credit_purchases, :sherlock_transaction_reference, unique: true, where: "sherlock_transaction_reference IS NOT NULL"
    add_index :credit_purchases, :created_at
  end
end
