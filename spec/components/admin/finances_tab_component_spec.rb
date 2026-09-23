# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::FinancesTabComponent, type: :component do
  let(:component) do
    described_class.new(
      revenues: { week: 300.0, month: 1200.0, year: 9000.0 },
      coach_salaries: { week: 100.0, month: 1500.0, year: 4000.0 },
      breakdowns: { sessions: { "entrainement" => 50.0 }, packs: { "credits" => 250.0 } }
    )
  end

  def card(title)
    page.find("span", text: title, exact_text: true).ancestor(".justify-between")
  end

  before { render_inline(component) }

  it "shows revenue and salaries for each period" do
    expect(card("CA Semaine")).to have_text("300,00 €")
    expect(card("CA Année")).to have_css(".bg-purple-50")
    expect(card("Salaires Mois")).to have_text("1 500,00 €")
    expect(card("Salaires Mois")).to have_css(".bg-orange-50")
  end

  it "shows the profit of each period, green when positive and red when negative" do
    expect(card("Bénéfice Semaine")).to have_text("200,00 €")
    expect(card("Bénéfice Semaine")).to have_css(".bg-green-50")
    expect(card("Bénéfice Mois")).to have_text("-300,00 €")
    expect(card("Bénéfice Mois")).to have_css(".bg-red-50")
  end
end
