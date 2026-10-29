# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shop::Campaign do
  it "refuse une clôture avant l'ouverture" do
    campaign = build(:shop_campaign, opens_on: Date.new(2026, 11, 17), closes_on: Date.new(2026, 11, 3))

    expect(campaign).not_to be_valid
    expect(campaign.errors.attribute_names).to include(:closes_on)
  end

  describe ".accepting_orders" do
    let(:today) { Date.new(2026, 11, 10) }

    it "ne garde que les campagnes ouvertes dont la période couvre le jour, bornes comprises" do
      ouverte = create(:shop_campaign, opens_on: Date.new(2026, 11, 3), closes_on: today)
      create(:shop_campaign, status: "draft", opens_on: Date.new(2026, 11, 3), closes_on: Date.new(2026, 11, 17))
      create(:shop_campaign, status: "closed", opens_on: Date.new(2026, 11, 3), closes_on: Date.new(2026, 11, 17))
      create(:shop_campaign, opens_on: Date.new(2026, 11, 11), closes_on: Date.new(2026, 11, 20))

      expect(described_class.accepting_orders(on: today)).to eq([ ouverte ])
    end
  end

  it "désigne la campagne ouverte aux commandes, ou rien" do
    expect(described_class.for_members).to be_nil

    campaign = create(:shop_campaign)

    expect(described_class.for_members).to eq(campaign)
    expect(campaign).to be_accepting_orders
  end

  it "n'ouvre la boutique qu'aux licenciés à jour" do
    campaign = create(:shop_campaign)

    expect(described_class.for_member(build(:user, activated_at: Time.current))).to eq(campaign)
    expect(described_class.for_member(build(:user, activated_at: nil))).to be_nil
    expect(described_class.for_member(nil)).to be_nil
  end
end
