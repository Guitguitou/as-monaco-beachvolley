# frozen_string_literal: true

require "rails_helper"

RSpec.describe PodiumComponent, type: :component do
  let(:alice) { build_stubbed(:user, first_name: "Alice", last_name: "Martin") }
  let(:bob) { build_stubbed(:user, first_name: "Bob", last_name: "Durand") }
  let(:chloe) { build_stubbed(:user, first_name: "Chloé", last_name: "Petit") }

  it "gives each of the three first players their medal" do
    players = [ { user: alice, name: "Alice", count: 5 }, { user: bob, name: "Bob", count: 3 }, { user: chloe, name: "Chloé", count: 1 } ]

    render_inline(described_class.new(players: players, title: "Top"))

    expect(page).to have_text("🥇")
    expect(page).to have_text("🥈")
    expect(page).to have_text("🥉")
  end

  it "keeps the ranking order in the list for screen readers" do
    players = [ { user: alice, name: "Alice", count: 5 }, { user: bob, name: "Bob", count: 3 } ]

    render_inline(described_class.new(players: players, title: "Top"))

    expect(page.all("ol > li").map(&:text).first).to include("Alice")
  end

  it "flags the current user" do
    render_inline(described_class.new(players: [ { user: alice, name: "Alice", count: 5 } ], title: "Top", current_user_id: alice.id))

    expect(page).to have_text("Toi")
  end

  it "shows inactivity as days since the last session" do
    player = { user: alice, name: "Alice", days_since: 12, last_session_at: Time.zone.local(2026, 3, 1, 10) }

    render_inline(described_class.new(players: [ player ], title: "Porté disparu"))

    expect(page.text.squish).to include("12 jours")
    expect(page).to have_text("depuis le 01/03/2026")
  end

  it "shows the empty message without players" do
    render_inline(described_class.new(players: [], title: "Top", empty_message: "Rien ici"))

    expect(page).to have_text("Rien ici")
  end
end
