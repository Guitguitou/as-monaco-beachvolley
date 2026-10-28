# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shop::Product do
  it "exige un nom et une marque" do
    product = build(:shop_product, name: "", brand: "")

    expect(product).not_to be_valid
    expect(product.errors.attribute_names).to include(:name, :brand)
  end

  it "range les articles par position puis par nom" do
    sac = create(:shop_product, name: "Sac", position: 2)
    short = create(:shop_product, name: "Short", position: 1)
    parka = create(:shop_product, name: "Parka", position: 1)

    expect(described_class.ordered).to eq([ parka, short, sac ])
  end

  it "ne garde que les articles en vente" do
    on_sale = create(:shop_product)
    create(:shop_product, active: false)

    expect(described_class.on_sale).to eq([ on_sale ])
  end
end
