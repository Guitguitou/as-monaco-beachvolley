require "rails_helper"

RSpec.describe EmptyStateComponent, type: :component do
  it "affiche l'icône, le titre et la description" do
    render_inline(described_class.new(
      icon: "volleyball", title: "Rien de prévu", description: "Aucune session à venir."
    ))

    expect(page).to have_css("svg")
    expect(page).to have_text("Rien de prévu")
    expect(page).to have_text("Aucune session à venir.")
  end

  it "fonctionne sans description" do
    render_inline(described_class.new(icon: "volleyball", title: "Rien de prévu"))

    expect(page).to have_text("Rien de prévu")
    expect(page).to have_css("p", count: 1)
  end

  it "rend une carte par défaut" do
    render_inline(described_class.new(icon: "volleyball", title: "Vide"))

    expect(page).to have_css("div.border.rounded-xl")
  end

  # Variante pour un état vide à l'intérieur d'une carte existante, où un
  # second cadre ferait doublon.
  it "supprime le cadre en mode compact" do
    render_inline(described_class.new(icon: "volleyball", title: "Vide", compact: true))

    expect(page).not_to have_css("div.rounded-xl")
  end

  it "rend le slot action" do
    render_inline(described_class.new(icon: "volleyball", title: "Vide")) do |empty|
      empty.with_action { "VOIR LES SESSIONS" }
    end

    expect(page).to have_text("VOIR LES SESSIONS")
  end
end
