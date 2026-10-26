# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::KpiTileComponent, type: :component do
  def metric(current:, previous:, higher_is_better: true)
    Reporting::Comparison.new(key: :x, label: "Inscriptions", icon: "users", current: current, previous: previous,
                               higher_is_better: higher_is_better)
  end

  it "affiche la valeur et sa progression en vert" do
    render_inline(described_class.new(metric: metric(current: 12, previous: 10)))

    expect(page).to have_text("12")
    expect(page).to have_css(".text-green-700", text: "+20 % · 10 la semaine passée")
  end

  it "colore en rouge une hausse quand moins est mieux" do
    render_inline(described_class.new(metric: metric(current: 30, previous: 10, higher_is_better: false)))

    expect(page).to have_css(".text-red-700", text: "+200 %")
  end
end
