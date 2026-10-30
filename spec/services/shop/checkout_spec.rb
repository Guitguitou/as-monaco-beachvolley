# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shop::Checkout do
  let(:user) { create(:user) }
  let(:campaign) { create(:shop_campaign) }
  let(:order) { create(:shop_order, user: user, campaign: campaign) }

  before do
    create(:shop_order_line, order: order, quantity: 2, unit_price_cents: 1800)
    create(:shop_order_line, order: order, quantity: 1, unit_price_cents: 1400)
  end

  it "verrouille le panier et ouvre un achat du montant calculé, sans pack" do
    result = described_class.new(order: order).call

    purchase = result.purchase
    expect(result.error).to be_nil
    expect(order.reload).to be_awaiting_payment_status
    expect([ purchase.amount_cents, purchase.shop_order, purchase.pack, purchase.credits ]).to eq([ 5000, order, nil, 0 ])
    expect(result.payment_request.url).to be_present
  end

  it "refuse un panier vide" do
    empty = create(:shop_order, campaign: campaign)

    expect(described_class.new(order: empty).call.error).to eq("Ton panier est vide.")
  end

  it "refuse quand la campagne n'accepte plus de commandes" do
    campaign.update!(closes_on: Date.current - 1, opens_on: Date.current - 10)

    expect(described_class.new(order: order).call.error).to eq("Les commandes sont fermées.")
    expect(order.reload).to be_cart_status
  end

  it "refuse un article retiré de la vente depuis l'ajout" do
    Shop::OrderLine.of(order).first.product.update!(active: false)

    expect(described_class.new(order: order).call.error).to match(/n'est plus en vente/)
  end
end
