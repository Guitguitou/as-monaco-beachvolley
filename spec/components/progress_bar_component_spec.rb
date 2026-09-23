# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProgressBarComponent, type: :component do
  it "fills the bar in proportion and colors it by variant" do
    render_inline(described_class.new(value: 3, max: 12, variant: :free_play, height: :md))

    expect(page).to have_css("[role=progressbar].h-2\\.5 div.bg-green-600[style*='width: 25.0%']")
  end

  it "caps the bar at full and falls back to the club color" do
    render_inline(described_class.new(value: 20, max: 10, variant: :other))

    expect(page).to have_css("[role=progressbar].h-2 div.bg-asmbv-red[style*='width: 100']")
  end

  it "stays empty without a maximum" do
    render_inline(described_class.new(value: 3, max: 0))

    expect(page).to have_css("div[style*='width: 0%']")
  end
end
