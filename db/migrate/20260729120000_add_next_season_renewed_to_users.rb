class AddNextSeasonRenewedToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :next_season_renewed, :boolean, null: false, default: false
  end
end
