class CreateLateCancellations < ActiveRecord::Migration[8.0]
  def change
    create_table :late_cancellations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :session, null: false, foreign_key: true

      t.timestamps
    end

    add_index :late_cancellations, [:user_id, :created_at]
  end
end
