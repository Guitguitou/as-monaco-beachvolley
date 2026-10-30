# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::ShopTabsComponent, type: :component do
  it "affiche les onglets de la boutique équipements et marque l'onglet courant" do
    render_inline(described_class.new(active: :size_guides))

    expect(page).to have_css("h1", text: "Boutique équipements")
    expect(page).to have_link("Articles", href: "/admin/equipements/articles")
    expect(page).to have_css("a.border-brand", text: "Guides des tailles")
  end
end
