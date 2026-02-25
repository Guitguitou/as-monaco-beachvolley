class AddPublicToPacks < ActiveRecord::Migration[8.0]
  def change
    add_column :packs, :public, :boolean, default: false, null: false
  end
end
