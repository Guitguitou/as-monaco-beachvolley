# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shop::AddToCart do
  let(:user) { create(:user) }
  let(:campaign) { create(:shop_campaign) }
  let(:product) { create(:shop_product, name: "T-shirt Varone") }
  let(:cut) { create(:shop_cut, product: product, label: "Femme", price_cents: 1800, sizes: %w[S M L]) }
  let(:color) { create(:shop_color, product: product, name: "Noir") }

  def add(**overrides)
    described_class.new(user: user, campaign: campaign, cut: cut, color: color, size: "M", quantity: 1, **overrides).call
  end

  it "crée le panier et y ajoute la ligne avec le libellé et le prix du moment" do
    result = add

    line = result.line
    expect(result.error).to be_nil
    expect(line.order).to eq(Shop::Order.cart_for(user, campaign))
    expect(line.attributes.slice("product_name", "cut_label", "color_name", "size", "unit_price_cents"))
      .to eq("product_name" => "T-shirt Varone", "cut_label" => "Femme", "color_name" => "Noir", "size" => "M", "unit_price_cents" => 1800)
  end

  it "regroupe un même article déjà au panier" do
    add(quantity: 1)
    result = add(quantity: 2)

    expect(Shop::OrderLine.of(result.line.order).sole.quantity).to eq(3)
  end

  it "refuse une taille hors de la coupe" do
    expect(add(size: "4XL").error).to eq("Choisis une taille de la liste.")
  end

  it "refuse un coloris d'un autre article" do
    expect(add(color: create(:shop_color)).error).to eq("Ce coloris n'existe pas pour cet article.")
  end

  it "refuse un article retiré de la vente" do
    product.update!(active: false)

    expect(add.error).to eq("Cet article n'est plus en vente.")
  end

  it "refuse quand la campagne n'accepte plus de commandes" do
    campaign.update!(status: "closed")

    expect(add.error).to eq("Les commandes sont fermées.")
    expect(Shop::Order.cart_for(user, campaign)).to be_nil
  end
end
