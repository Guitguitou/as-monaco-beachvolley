class AddSeriesIdToSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :sessions, :series_id, :string
    add_index :sessions, :series_id
  end
end
