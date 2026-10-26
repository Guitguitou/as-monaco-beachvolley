# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reporting::SeasonRevenue do
  let(:months) { Reporting::SeasonMonths.new(Season.new(starts_on: Date.new(2026, 9, 1)), today: Date.new(2026, 10, 20)) }

  before do
    create(:credit_purchase, :paid, pack: create(:pack, :licence), amount_cents: 9000, paid_at: Time.zone.local(2026, 9, 5))
    create(:credit_purchase, :paid, amount_cents: 1000, paid_at: Time.zone.local(2026, 10, 2))
    create(:credit_purchase, :paid, amount_cents: 2000, paid_at: Time.zone.local(2025, 9, 20))
    create(:credit_purchase, amount_cents: 5000, created_at: Time.zone.local(2026, 10, 3))
  end

  it "ventile l'encaissé payé par type de pack et par mois" do
    series = described_class.new(months).revenue_by_pack_type

    expect(series.map { |s| s[:name] }).to eq([ "Licence", "Achat direct" ])
    expect(series.first[:data].values).to eq([ 90, 0 ])
  end

  it "compare à la saison précédente à date égale" do
    revenue, purchases, _buyers, basket = described_class.new(months).comparisons

    expect([ revenue.current, revenue.previous, purchases.current, basket.current ]).to eq([ 100, 20, 2, 50 ])
  end
end
