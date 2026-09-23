# frozen_string_literal: true

require "rails_helper"

RSpec.describe BadgeComponent, type: :component do
  it "styles the badge from its variant and size" do
    render_inline(described_class.new(label: "Complet", variant: :danger, size: :md))

    expect(page).to have_css("span.rounded-full.bg-red-600.border-red-700.px-3.text-xs", text: "Complet")
  end

  it "treats destructive like danger" do
    render_inline(described_class.new(label: "Annulée", variant: "destructive"))

    expect(page).to have_css("span.bg-red-600")
  end

  it "falls back to the neutral look and small size" do
    render_inline(described_class.new(label: "Info", variant: :unknown, size: :huge))

    expect(page).to have_css("span.bg-white.border-gray-300.px-2\\.5")
  end
end
