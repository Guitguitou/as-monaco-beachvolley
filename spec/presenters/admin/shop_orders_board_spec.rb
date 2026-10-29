# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::ShopOrdersBoard do
  let(:campaign) { create(:shop_campaign) }
  let!(:paid) { create(:shop_order, campaign: campaign).tap { |order| create(:shop_order_line, order: order, quantity: 2, unit_price_cents: 1800) }.tap(&:mark_paid!) }
  let!(:unfinished) { create(:shop_order, campaign: campaign, status: "awaiting_payment").tap { |order| create(:shop_order_line, order: order) } }

  before { create(:shop_order, campaign: campaign) } # panier vide : ignoré

  it "chiffre la campagne" do
    board = described_class.new(campaign: campaign, filter: nil)

    expect(board.kpis.map(&:value)).to eq([ "1", "36,00 €", "2", "1" ])
  end

  it "liste les commandes payées puis non finalisées, ou un seul des deux" do
    expect(described_class.new(campaign: campaign, filter: nil).orders).to eq([ paid, unfinished ])
    expect(described_class.new(campaign: campaign, filter: "paid").orders).to eq([ paid ])
    expect(described_class.new(campaign: campaign, filter: "unfinished").orders).to eq([ unfinished ])
  end
end
