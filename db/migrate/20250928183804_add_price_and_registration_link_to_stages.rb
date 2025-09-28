class AddPriceAndRegistrationLinkToStages < ActiveRecord::Migration[8.0]
  def change
    add_column :stages, :price_cents, :integer
    add_column :stages, :registration_link, :string
  end
end
