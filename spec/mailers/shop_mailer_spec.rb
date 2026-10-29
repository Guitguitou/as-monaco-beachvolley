# frozen_string_literal: true

require "rails_helper"

RSpec.describe ShopMailer do
  it "relance un membre dont la commande n'est pas payée" do
    order = create(:shop_order, campaign: create(:shop_campaign, closes_on: Date.new(2026, 11, 17)))

    mail = described_class.unfinished_order(order)

    expect(mail.to).to eq([ order.user.email ])
    expect(mail.subject).to eq("Ta commande d'équipements n'est pas encore payée")
    expect(mail.body.encoded).to include("17 novembre 2026", "/equipements/panier")
  end
end
