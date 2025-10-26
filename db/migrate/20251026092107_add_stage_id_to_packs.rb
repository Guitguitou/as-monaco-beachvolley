class AddStageIdToPacks < ActiveRecord::Migration[8.0]
  def change
    add_column :packs, :stage_id, :integer
    add_index :packs, :stage_id
    add_foreign_key :packs, :stages, column: :stage_id
  end
end
