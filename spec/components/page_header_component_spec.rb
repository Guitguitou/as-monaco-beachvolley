# frozen_string_literal: true

require "rails_helper"

RSpec.describe PageHeaderComponent, type: :component do
  it "rend l'en-tête compact par défaut" do
    render_inline(described_class.new(title: "Calendrier"))

    expect(page).to have_css("header h1.font-anton", text: "Calendrier")
  end

  it "rend l'en-tête admin avec son icône et ses actions" do
    render_inline(described_class.new(title: "Terrains", icon: "map-pin", variant: :admin)) do |header|
      header.with_actions { "Nouveau terrain" }
    end

    expect(page).not_to have_css("header")
    expect(page).to have_css("h1.text-2xl.font-bold svg")
    expect(page).to have_css("h1", text: "Terrains")
    expect(page).to have_text("Nouveau terrain")
  end
end
