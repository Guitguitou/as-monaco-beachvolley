# frozen_string_literal: true

require "rails_helper"

RSpec.describe RankingComponent, type: :component do
  def players(count)
    (1..count).map do |rank|
      { rank: rank, user: build_stubbed(:user), name: "Joueur #{rank}", count: 20 - rank }
    end
  end

  it "hides players beyond the visible ones behind a toggle" do
    render_inline(described_class.new(players: players(12), visible: 10))

    expect(page).to have_css("li[hidden]", count: 2, visible: :all)
    expect(page).to have_button("Voir les 2 autres")
  end

  it "scales each bar against the leader" do
    render_inline(described_class.new(players: [ { rank: 1, user: build_stubbed(:user), name: "A", count: 10 },
                                                 { rank: 2, user: build_stubbed(:user), name: "B", count: 5 } ]))

    expect(page).to have_css("[style='width: 50%']")
  end

  it "offers to locate the current user when ranked" do
    list = players(3)

    render_inline(described_class.new(players: list, current_user_id: list.last[:user].id))

    expect(page).to have_button("Me trouver")
    expect(page).to have_css("li[data-me]", text: "Toi")
  end

  it "indexes names without accents for the search" do
    render_inline(described_class.new(players: [ { rank: 1, user: build_stubbed(:user), name: "Cécilia Élan", count: 1 } ]))

    expect(page).to have_css("li[data-name='cecilia elan']")
  end
end
