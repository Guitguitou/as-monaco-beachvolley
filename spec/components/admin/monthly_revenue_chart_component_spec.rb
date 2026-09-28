# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::MonthlyRevenueChartComponent, type: :component do
  def month(month, by_type)
    {
      period: I18n.l(Date.new(2024, month), format: :month_and_year),
      month: month,
      year: 2024,
      by_type: by_type.transform_values { |amount| { count: 1, amount: amount } },
      total: by_type.values.sum
    }
  end

  let(:months) do
    [
      month(1, "credits" => 100.0),
      month(2, "credits" => 150.0, "licence" => 50.0),
      month(3, "credits" => 120.0)
    ]
  end

  before { render_inline(described_class.new(months: months, pack_types: Pack.pack_types.keys)) }

  it "draws one stacked segment per type sold each month" do
    expect(page).to have_css("svg rect", count: 4)
    expect(page).to have_css("rect.fill-asmbv-red", count: 3)
    expect(page).to have_css("rect.fill-asmbv-ocean", count: 1)
  end

  it "only lists the pack types sold over the period" do
    expect(page).to have_css("th", text: "Crédits")
    expect(page).to have_css("th", text: "Licences")
    expect(page).not_to have_css("th", text: "Stages")
  end

  it "compares the current month with the previous one" do
    expect(page).to have_text("-40 %") # mars 120 € vs février 200 €
  end

  it "compares each pack type month over month, most recent first" do
    march = page.all("tbody tr").first
    expect(march).to have_text("mars 2024")
    expect(march).to have_text("-20 %") # crédits 120 € vs 150 €
    expect(march).to have_text("-100 %") # licences 0 € vs 50 €

    january = page.all("tbody tr").last
    expect(january).to have_text("—")
  end

  context "without any sale" do
    let(:months) { [ month(1, {}), month(2, {}) ] }

    it "shows an empty state instead of the chart" do
      expect(page).to have_text("Aucune vente de pack sur la période")
      expect(page).not_to have_css("svg[role=img]")
    end
  end
end
