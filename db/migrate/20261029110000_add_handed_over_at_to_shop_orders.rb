# frozen_string_literal: true

# Remise de l'équipement au membre, suivie par le Staff depuis le back-office.
class AddHandedOverAtToShopOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :shop_orders, :handed_over_at, :datetime
  end
end
