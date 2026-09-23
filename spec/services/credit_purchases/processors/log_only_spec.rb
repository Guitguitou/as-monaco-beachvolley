# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreditPurchases::Processors::LogOnly do
  let(:pack) { create(:pack, pack_type: "equipements", name: "Maillot") }

  before { allow(Rails.logger).to receive(:info) }

  it "only logs the purchase, since nothing is credited for this pack" do
    user = create(:user)
    purchase = create(:credit_purchase, user: user, pack: pack, amount_cents: 3000)

    described_class.new(purchase: purchase, label: "Equipements").call

    expect(Rails.logger).to have_received(:info).with("Equipements pack purchased: Maillot by user #{user.id}")
  end
end
