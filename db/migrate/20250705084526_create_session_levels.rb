class CreateSessionLevels < ActiveRecord::Migration[8.0]
  def change
    create_table :session_levels do |t|
      t.references :session, null: false, foreign_key: true
      t.references :level, null: false, foreign_key: true

      t.timestamps
    end
  end
end
