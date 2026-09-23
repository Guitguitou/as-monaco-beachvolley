# frozen_string_literal: true

require "rails_helper"

RSpec.describe HeroComponent, type: :component do
  it "renders a red banner with white text by default" do
    render_inline(described_class.new(title: "Planning", subtitle: "Cette semaine"))

    expect(page).to have_css("section.bg-asmbv-red h1.text-white.font-bebas-neue.mt-3", text: "Planning")
    expect(page).to have_css("p.text-white", text: "Cette semaine")
  end

  it "renders a white banner with dark text" do
    render_inline(described_class.new(title: "Profil", subtitle: "Saison", variant: :white, title_font: :anton, flush_title: true))

    expect(page).to have_css("section.bg-white h1.text-gray-900.font-anton:not(.mt-3)")
    expect(page).to have_css("p.text-gray-600")
  end

  it "falls back to the dark banner" do
    render_inline(described_class.new(title: "Admin", variant: :unknown))

    expect(page).to have_css("section.bg-gray-900")
  end
end
