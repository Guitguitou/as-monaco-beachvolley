class CreateSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :sessions do |t|
      t.string :title
      t.text :description
      t.datetime :start_at
      t.datetime :end_at
      t.string :session_type
      t.references :user, null: false, foreign_key: true
      t.integer :max_players

      t.timestamps
    end
  end
end
