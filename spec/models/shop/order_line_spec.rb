# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shop::OrderLine do
  it "limite la quantité entre 1 et 20" do
    expect(build(:shop_order_line, quantity: 0)).not_to be_valid
    expect(build(:shop_order_line, quantity: 21)).not_to be_valid
    expect(build(:shop_order_line, quantity: 20)).to be_valid
  end

  it "résume le coloris, la coupe et la taille" do
    line = build(:shop_order_line, color_name: "Noir", cut_label: "Femme", size: "S")

    expect(line.details).to eq("Noir · Femme · S")
    expect(line.total_cents).to eq(line.unit_price_cents)
  end

  it "date la commande quand une ligne change, pour le suivi par updated_since" do
    line = create(:shop_order_line)
    order = line.order
    order.update_column(:updated_at, 2.days.ago)

    line.update!(size: "L")

    expect(order.reload.updated_at).to be_within(1.minute).of(Time.current)
  end
end
