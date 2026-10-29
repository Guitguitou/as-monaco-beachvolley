# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Exports du récap de campagne" do
  let(:campaign) { create(:shop_campaign, name: "Commande groupée 2026-2027") }
  let(:product) { create(:shop_product, name: "T-shirt Varone", brand: "Nine") }
  let(:cut) { create(:shop_cut, product: product, label: "Femme", sizes: %w[S M L]) }
  let(:order) { create(:shop_order, campaign: campaign, team: "Seniors F").tap(&:mark_paid!) }

  before do
    create(:shop_order_line, order: order, cut: cut, product: product, product_name: "T-shirt Varone",
                             cut_label: "Femme", color_name: "Noir", size: "M", quantity: 2)
  end

  it "liste la distribution par membre" do
    expect(Shop::DistributionList.new(campaign).rows.last)
      .to eq([ order.number, order.user.full_name, "Seniors F", "T-shirt Varone", "Noir", "Femme", "M", 2 ])
  end

  it "produit un classeur Excel avec le récap et la distribution" do
    expect(Shop::RecapWorkbook.new(campaign).render.byteslice(0, 2)).to eq("PK")
  end

  it "produit un PDF, même avec un nom hors de l'alphabet de la police" do
    order.user.update!(last_name: "Łukasiewicz 🏐")

    expect(Shop::RecapPdf.new(campaign).render).to start_with("%PDF")
  end
end
