# frozen_string_literal: true

require "rails_helper"

RSpec.describe PodiumComponent, type: :component do
  it "gives each of the three first players their medal" do
    players = [ { name: "Alice", count: 5 }, { name: "Bob", count: 3 }, { name: "Chloé", count: 1 } ]

    render_inline(described_class.new(players: players, title: "Top"))

    expect(page).to have_text("🥇")
    expect(page).to have_text("🥈")
    expect(page).to have_text("🥉")
  end
end
