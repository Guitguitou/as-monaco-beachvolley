class CreateLevels < ActiveRecord::Migration[8.0]
  def change
    create_table :levels do |t|
      t.string :name
      t.string :gender
      t.string :color

      t.timestamps
    end
  end
end
