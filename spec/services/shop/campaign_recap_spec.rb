# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shop::CampaignRecap do
  let(:campaign) { create(:shop_campaign) }
  let(:joma) { create(:shop_product, name: "Sweat zippé", brand: "Joma") }
  let(:nine) { create(:shop_product, name: "T-shirt Varone", brand: "Nine") }
  let(:sweat) { create(:shop_cut, product: joma, label: "Unisexe", sizes: %w[XS S M L]) }
  let(:varone) { create(:shop_cut, product: nine, label: "Femme", sizes: %w[S M L]) }

  def line(order, cut, color, size, quantity)
    create(:shop_order_line, order: order, cut: cut, product: cut.product, product_name: cut.product.name,
                             cut_label: cut.label, color_name: color, size: size, quantity: quantity)
  end

  before do
    paid = create(:shop_order, campaign: campaign).tap(&:mark_paid!)
    line(paid, varone, "Noir", "M", 2)
    line(paid, sweat, "Rouge", "M", 1)
    other = create(:shop_order, campaign: campaign).tap(&:mark_paid!)
    line(other, varone, "Noir", "S", 1)
    line(other, sweat, "Rouge", "XS", 1)
    line(create(:shop_order, campaign: campaign), varone, "Noir", "L", 5)
  end

  it "regroupe les lignes payées par marque, article, coloris et coupe, tailles dans l'ordre de la coupe" do
    brands = described_class.new(campaign).brands

    expect(brands.map(&:name)).to eq(%w[Joma Nine])
    expect(brands.map { |brand| brand.rows.map { |row| [ row.label, row.sizes, row.quantity ] } }).to eq([
      [ [ "Sweat zippé · Rouge · Unisexe", [ [ "XS", 1 ], [ "M", 1 ] ], 2 ] ],
      [ [ "T-shirt Varone · Noir · Femme", [ [ "S", 1 ], [ "M", 2 ] ], 3 ] ]
    ])
    expect(brands.map(&:quantity)).to eq([ 2, 3 ])
  end

  it "met à plat le récap pour le tableur, une ligne par taille" do
    rows = described_class.new(campaign).flat_rows

    expect(rows.first).to eq([ "Marque", "Article", "Coloris", "Coupe", "Taille", "Quantité" ])
    expect(rows.drop(1)).to include([ "Nine", "T-shirt Varone", "Noir", "Femme", "M", 2 ])
    expect(rows.size).to eq(5)
  end
end
