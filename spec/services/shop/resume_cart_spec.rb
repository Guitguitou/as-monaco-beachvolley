# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shop::ResumeCart do
  let(:order) { create(:shop_order, status: "awaiting_payment") }

  def resume = described_class.new(user: order.user, campaign: order.campaign).call

  def purchase(status) = create(:credit_purchase, user: order.user, pack: nil, shop_order: order, credits: 0, status: status)

  it "rend le panier en cours" do
    order.update!(status: "cart")

    expect(resume).to eq(order)
  end

  it "rouvre le panier quand le dernier paiement a échoué ou été abandonné" do
    purchase("cancelled")

    expect(resume).to eq(order)
    expect(order.reload).to be_cart_status
  end

  it "laisse la commande verrouillée tant que le paiement est en cours" do
    purchase("pending")

    expect(resume).to be_nil
    expect(order.reload).to be_awaiting_payment_status
  end

  it "ne rouvre pas une commande payée" do
    order.update!(status: "paid")
    purchase("paid")

    expect(resume).to be_nil
  end
end
