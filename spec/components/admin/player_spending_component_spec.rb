# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::PlayerSpendingComponent, type: :component do
  let(:stat) { Reporting::PlayerSessionSpending::Stat }
  let(:period) { Admin::SessionsPeriod.new("month", "2026-09") }
  let(:alice) { build_stubbed(:user, first_name: "Alice", last_name: "Martin") }
  let(:rows) do
    [ Reporting::PlayerSessionSpending::Row.new(
      user: alice,
      by_type: { "entrainement" => stat.new(count: 2, amount: 16.0) }
    ) ]
  end
  let(:spending) do
    instance_double(Reporting::PlayerSessionSpending,
                    rows: rows,
                    session_types: %w[entrainement],
                    totals: { "entrainement" => stat.new(count: 2, amount: 16.0) })
  end

  before { render_inline(described_class.new(spending: spending, period: period)) }

  it "shows each player with sessions and euros per type" do
    row = page.find("tbody tr", text: "Alice Martin")

    expect(row).to have_text("16,00 €")
    expect(row).to have_text("2 sessions")
  end

  it "navigates between periods" do
    expect(page).to have_text("septembre 2026")
    expect(page).to have_link(href: "/admin/finances?period=month&period_anchor=2026-08#players")
  end

  context "without any paid session" do
    let(:rows) { [] }

    it "shows an empty state" do
      expect(page).to have_text("Aucune session payée sur la période")
    end
  end
end
