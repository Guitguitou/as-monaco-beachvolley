class AddLevelToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :level, foreign_key: true, null: true
  end
end
