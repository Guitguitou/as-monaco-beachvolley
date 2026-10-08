# frozen_string_literal: true

require "rails_helper"

RSpec.describe SortableComponent, type: :component do
  it "rend une liste branchée sur le contrôleur sortable, un élément par id" do
    render_inline(described_class.new(url: "/admin/reorder", class_name: "grid")) do |list|
      list.with_item(id: 1) { "Un" }
      list.with_item(id: 2, class_name: "p-2") { "Deux" }
    end

    expect(page).to have_css("ul.grid[data-controller='sortable'][data-sortable-url-value='/admin/reorder'][data-sortable-param-value='ids']")
    expect(page).to have_css("li[data-sortable-target='item'][data-sortable-id='1']", text: "Un")
    expect(page).to have_css("li.p-2[data-sortable-id='2']", text: "Deux")
  end

  it "fournit une poignée qui démarre le glisser" do
    render_inline(SortableComponent::Handle.new(label: "Déplacer"))

    expect(page).to have_css("button[type='button'][aria-label='Déplacer'][data-action='pointerdown->sortable#start'].touch-none")
  end
end
