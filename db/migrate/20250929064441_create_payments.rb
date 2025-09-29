class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :credit_package, null: false, foreign_key: true
      t.string :status, default: 'pending'
      t.integer :amount_cents
      t.string :sherlock_transaction_id
      t.text :sherlock_response

      t.timestamps
    end
  end
end
