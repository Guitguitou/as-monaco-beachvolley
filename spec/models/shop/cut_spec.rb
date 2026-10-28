# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shop::Cut do
  it "exige un libellé et un prix positif" do
    cut = build(:shop_cut, label: "", price_cents: 0)

    expect(cut).not_to be_valid
    expect(cut.errors.attribute_names).to include(:label, :price_cents)
  end

  it "exige au moins une taille" do
    expect(build(:shop_cut, sizes: [])).not_to be_valid
  end

  it "lit et écrit le prix en euros" do
    cut = build(:shop_cut, price_eur: "14,5")

    expect(cut.price_cents).to eq(1450)
    expect(cut.price_eur).to eq(14.5)
  end

  it "lit et écrit les tailles séparées par des virgules, sans doublon ni vide" do
    cut = build(:shop_cut, sizes_text: " 2XS, XS,, S , S ")

    expect(cut.sizes).to eq(%w[2XS XS S])
    expect(cut.sizes_text).to eq("2XS, XS, S")
  end

  it "ordonne les coupes d'un article par position" do
    product = create(:shop_product)
    second = create(:shop_cut, product: product, position: 2)
    first = create(:shop_cut, product: product, position: 1)

    expect(described_class.of(product)).to eq([ first, second ])
  end
end
