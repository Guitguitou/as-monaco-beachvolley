class CreateStages < ActiveRecord::Migration[8.0]
  def change
    create_table :stages do |t|
      t.string :title
      t.text :description
      t.date :starts_on
      t.date :ends_on
      t.references :main_coach, foreign_key: { to_table: :users }
      t.references :assistant_coach, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
