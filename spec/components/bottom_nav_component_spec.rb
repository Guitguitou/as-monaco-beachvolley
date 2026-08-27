require "rails_helper"

RSpec.describe BottomNavComponent, type: :component do
  let(:activated) { build_stubbed(:user, activated_at: Time.current) }
  let(:pending) { build_stubbed(:user, activated_at: nil) }

  it "ne rend rien sans utilisateur" do
    render_inline(described_class.new(user: nil, current_path: "/mon-terrain"))

    expect(page).not_to have_css("nav")
  end

  it "propose les cinq destinations principales à un compte activé" do
    render_inline(described_class.new(user: activated, current_path: "/mon-terrain"))

    expect(page).to have_link("Terrain", href: "/mon-terrain")
    expect(page).to have_link("Calendrier", href: "/sessions")
    expect(page).to have_link("Annonces", href: "/annonces")
    expect(page).to have_link("Boutique", href: "/packs")
    expect(page).to have_link("Profil", href: "/profile")
  end

  it "limite les destinations d'un compte non activé" do
    render_inline(described_class.new(user: pending, current_path: "/packs"))

    expect(page).to have_link("Boutique")
    expect(page).to have_link("Stages")
    expect(page).to have_link("Profil")
    expect(page).not_to have_link("Calendrier")
    expect(page).not_to have_link("Annonces")
  end

  it "marque l'onglet courant" do
    render_inline(described_class.new(user: activated, current_path: "/sessions"))

    expect(page.find_link("Calendrier")["aria-current"]).to eq("page")
    expect(page.find_link("Profil")["aria-current"]).to be_nil
  end

  it "garde l'onglet actif sur les pages filles" do
    render_inline(described_class.new(user: activated, current_path: "/sessions/42"))

    expect(page.find_link("Calendrier")["aria-current"]).to eq("page")
  end

  it "n'active pas un onglet sur un préfixe partiel trompeur" do
    render_inline(described_class.new(user: activated, current_path: "/sessions-archive"))

    expect(page.find_link("Calendrier")["aria-current"]).to be_nil
  end

  it "reste masquée en desktop" do
    render_inline(described_class.new(user: activated, current_path: "/mon-terrain"))

    expect(page.find("nav")[:class]).to include("lg:hidden")
  end
end
