class ChangePriceToInteger < ActiveRecord::Migration[8.0]
  def change
    change_column :sessions, :price, :integer, default: 0, null: false
  end
end 
