# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::ConfigurationTabsComponent, type: :component do
  it "affiche les onglets de la configuration et marque l'onglet courant" do
    render_inline(described_class.new(active: :terrains))

    expect(page).to have_css("h1", text: "Configuration")
    expect(page).to have_link("Règles du club", href: "/admin/regles-du-club")
    expect(page).to have_link("Intégrations", href: "/admin/connexions-claude")
    expect(page).to have_css("a.border-brand", text: "Terrains")
  end

  it "affiche les actions de l'onglet dans l'en-tête" do
    render_inline(described_class.new(active: :terrains)) { |config| config.with_actions { "Nouveau terrain" } }

    expect(page).to have_text("Nouveau terrain")
  end
end
