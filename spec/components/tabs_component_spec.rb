require "rails_helper"

RSpec.describe TabsComponent, type: :component do
  let(:tabs) do
    [
      { label: "Toutes", href: "/sessions", active: true, count: 42 },
      { label: "Tournois", href: "/sessions?type=tournoi", active: false, count: 3, icon: "trophy" }
    ]
  end

  it "rend un lien par onglet vers son href" do
    render_inline(described_class.new(tabs: tabs))

    expect(page).to have_link("Toutes", href: "/sessions")
    expect(page).to have_link("Tournois", href: "/sessions?type=tournoi")
  end

  it "surligne l'onglet actif" do
    render_inline(described_class.new(tabs: tabs))

    active = page.find_link("Toutes")
    expect(active[:class]).to include("border-asmbv-red", "text-asmbv-red")

    inactive = page.find_link("Tournois")
    expect(inactive[:class]).to include("border-transparent", "text-gray-500")
  end

  it "affiche la pastille de comptage quand count est présent" do
    render_inline(described_class.new(tabs: [ { label: "Toutes", href: "/x", active: true, count: 42 } ]))

    expect(page).to have_text("42")
  end

  it "n'affiche pas de pastille quand count est nil" do
    render_inline(described_class.new(tabs: [ { label: "Profil", href: "/x", active: true } ]))

    expect(page).not_to have_css("span")
  end

  it "rend l'icône lucide quand icon est fourni" do
    render_inline(described_class.new(tabs: [ { label: "Tournois", href: "/x", active: false, icon: "trophy" } ]))

    expect(page).to have_css("svg")
  end

  it "ignore les onglets nil (onglets conditionnels)" do
    render_inline(described_class.new(tabs: [ { label: "Profil", href: "/x", active: true }, nil ]))

    expect(page).to have_link("Profil")
    expect(page).to have_selector("a", count: 1)
  end

  context "avec turbo_frame" do
    it "cible le frame et pousse l'URL dans l'historique" do
      render_inline(described_class.new(tabs: tabs, turbo_frame: "sessions_list"))

      link = page.find_link("Toutes")
      expect(link["data-turbo-frame"]).to eq("sessions_list")
      expect(link["data-turbo-action"]).to eq("advance")
    end
  end

  context "sans turbo_frame" do
    it "n'ajoute pas d'attributs turbo" do
      render_inline(described_class.new(tabs: tabs))

      link = page.find_link("Toutes")
      expect(link["data-turbo-frame"]).to be_nil
    end
  end
end
