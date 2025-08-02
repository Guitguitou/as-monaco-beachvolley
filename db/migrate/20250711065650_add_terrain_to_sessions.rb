class AddTerrainToSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :sessions, :terrain, :integer
  end
end
