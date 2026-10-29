# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::ShopOrders et récap", type: :request do
  include ActiveJob::TestHelper

  let(:campaign) { create(:shop_campaign, name: "Commande groupée 2026-2027") }
  let(:member) { create(:user, first_name: "Camille", last_name: "Rossi") }
  let(:paid) { create(:shop_order, campaign: campaign, user: member, team: "Seniors F").tap(&:mark_paid!) }
  let(:unfinished) { create(:shop_order, campaign: campaign) }

  before do
    sign_in create(:user, :admin)
    create(:shop_order_line, order: paid, product_name: "T-shirt Varone", color_name: "Noir", cut_label: "Femme", size: "M", quantity: 2)
    create(:shop_order_line, order: unfinished, product_name: "Parka")
  end

  it "liste les commandes de la campagne avec leurs chiffres" do
    get admin_shop_orders_path

    expect(response.body).to include(paid.number, "Camille Rossi", "Seniors F", "Non finalisée", "Commandes payées")
  end

  it "marque une commande payée comme remise, puis l'annule" do
    patch hand_over_admin_shop_order_path(paid)
    expect(paid.reload).to be_handed_over

    patch hand_over_admin_shop_order_path(paid)
    expect(paid.reload).not_to be_handed_over
  end

  it "relance par e-mail un membre dont la commande n'est pas payée" do
    expect { post remind_admin_shop_order_path(unfinished) }
      .to have_enqueued_mail(ShopMailer, :unfinished_order).with(unfinished)
  end

  it "clôture la campagne depuis les commandes" do
    patch admin_shop_campaign_path(campaign), params: { shop_campaign: { status: "closed" } }

    expect(campaign.reload).to be_closed_status
  end

  it "affiche le récap par marque et le télécharge en Excel et en PDF" do
    get admin_shop_recap_path
    expect(response.body).to include("T-shirt Varone", "Noir · Femme")

    get admin_shop_recap_excel_path(campaign_id: campaign.id)
    expect(response.headers["Content-Disposition"]).to include("recap-commande-groupee-2026-2027.xlsx")

    get admin_shop_recap_pdf_path(campaign_id: campaign.id)
    expect(response.media_type).to eq("application/pdf")
  end
end
