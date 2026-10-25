# frozen_string_literal: true

require "rails_helper"

RSpec.describe BackLinkComponent, type: :component do
  it "pointe vers l'adresse donnée avec « Retour » par défaut" do
    render_inline(described_class.new(href: "/infos"))

    expect(page).to have_link("Retour", href: "/infos")
  end

  it "accepte un libellé" do
    render_inline(described_class.new(href: "/admin/users", label: "Retour aux joueurs"))

    expect(page).to have_link("Retour aux joueurs", href: "/admin/users")
  end
end
