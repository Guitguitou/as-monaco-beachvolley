# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shop::Order do
  let(:order) { create(:shop_order) }

  it "additionne ses lignes au prix enregistré à l'ajout" do
    create(:shop_order_line, order: order, quantity: 2, unit_price_cents: 1800)
    create(:shop_order_line, order: order, quantity: 1, unit_price_cents: 1400)

    expect(order.total_cents).to eq(5000)
    expect(order.items_count).to eq(3)
  end

  it "trouve le panier d'un membre pour une campagne" do
    expect(described_class.cart_for(order.user, order.campaign)).to eq(order)
    expect(described_class.cart_for(create(:user), order.campaign)).to be_nil
  end
end
