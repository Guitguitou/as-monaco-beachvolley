# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::ShopCampaigns", type: :request do
  before { sign_in create(:user, :admin) }

  it "liste les campagnes et signale celle où les membres commandent" do
    create(:shop_campaign, name: "Commande groupée 2026-2027")

    get admin_shop_campaigns_path

    expect(response.body).to include("Commande groupée 2026-2027", "Les membres peuvent commander")
  end

  it "crée une campagne en brouillon" do
    post admin_shop_campaigns_path, params: { shop_campaign: { name: "Hiver", opens_on: "2026-11-03", closes_on: "2026-11-17", status: "draft" } }

    expect(Shop::Campaign.find_by!(name: "Hiver")).to be_draft_status
    expect(response).to redirect_to(admin_shop_campaigns_path)
  end

  it "réaffiche le formulaire quand la clôture précède l'ouverture" do
    post admin_shop_campaigns_path, params: { shop_campaign: { name: "Hiver", opens_on: "2026-11-17", closes_on: "2026-11-03" } }

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "ouvre une campagne" do
    campaign = create(:shop_campaign, status: "draft")

    patch admin_shop_campaign_path(campaign), params: { shop_campaign: { status: "open" } }

    expect(campaign.reload).to be_open_status
  end
end
