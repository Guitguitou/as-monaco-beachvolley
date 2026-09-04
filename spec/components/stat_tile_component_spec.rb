require "rails_helper"

RSpec.describe StatTileComponent, type: :component do
  it "affiche la valeur et le libellé" do
    render_inline(described_class.new(value: 12, label: "Sessions jouées"))

    expect(page).to have_text("12")
    expect(page).to have_text("Sessions jouées")
  end

  it "rend une div quand aucun href n'est fourni" do
    render_inline(described_class.new(value: 3, label: "À venir"))

    expect(page).not_to have_css("a")
    expect(page).to have_css("div.rounded-xl")
  end

  it "devient un lien quand href est fourni" do
    render_inline(described_class.new(value: 340, label: "Tes crédits", href: "/packs"))

    link = page.find("a")
    expect(link[:href]).to eq("/packs")
    expect(link[:class]).to include("hover:border-asmbv-red")
  end

  # Les onglets du profil vivent dans un turbo_frame : un lien sortant doit
  # viser _top, sinon la page cible se charge à l'intérieur du frame.
  it "vise _top pour un lien sortant" do
    render_inline(described_class.new(value: 1, label: "Crédits", href: "/packs", external: true))

    expect(page.find("a")["data-turbo-frame"]).to eq("_top")
  end

  it "n'ajoute pas d'attribut turbo pour un lien interne" do
    render_inline(described_class.new(value: 1, label: "Crédits", href: "/packs"))

    expect(page.find("a")["data-turbo-frame"]).to be_nil
  end

  it "affiche l'indication complémentaire quand hint est fourni" do
    render_inline(described_class.new(value: 5, label: "Jouées", hint: "depuis septembre"))

    expect(page).to have_text("depuis septembre")
  end

  it "n'affiche pas de hint quand il est absent" do
    render_inline(described_class.new(value: 5, label: "Jouées"))

    expect(page).to have_css("p", count: 2)
  end

  it "rend l'icône lucide quand icon est fourni" do
    render_inline(described_class.new(value: 5, label: "Jouées", icon: "volleyball"))

    expect(page).to have_css("svg")
  end

  it "utilise la typographie display pour la valeur" do
    render_inline(described_class.new(value: 42, label: "Total"))

    expect(page).to have_css("p.font-anton.tabular-nums", text: "42")
  end

  context "avec le ton accent" do
    it "inverse les couleurs sur fond sombre" do
      render_inline(described_class.new(value: 7, label: "Solde", tone: :accent))

      expect(page).to have_css("div.bg-gray-900")
      expect(page).to have_css("p.text-white", text: "7")
    end
  end

  context "avec un slot action" do
    it "rend l'action sous la valeur" do
      render_inline(described_class.new(value: 0, label: "Tes crédits")) do |tile|
        tile.with_action { "RECHARGER" }
      end

      expect(page).to have_text("RECHARGER")
    end
  end
end
