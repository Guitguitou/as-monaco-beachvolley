require "rails_helper"

RSpec.describe AvatarComponent, type: :component do
  it "affiche les initiales du prénom et du nom" do
    render_inline(described_class.new(user: build(:user, first_name: "Zoé", last_name: "Martin")))

    expect(page).to have_text("ZM")
  end

  it "se rabat sur le nom complet quand un champ manque" do
    render_inline(described_class.new(user: build(:user, first_name: "", last_name: "Martin")))

    expect(page).to have_text("MA")
  end

  it "affiche un point d'interrogation sans utilisateur" do
    render_inline(described_class.new(user: nil))

    expect(page).to have_text("?")
  end

  # Taille du hero de profil, qui remplace le calcul d'initiales recopié à la
  # main dans users/show.
  it "rend la taille xl en typographie display et responsive" do
    render_inline(described_class.new(user: build(:user), size: :xl))

    classes = page.find("span, div")[:class]
    expect(classes).to include("h-16", "w-16", "sm:h-20", "font-anton")
  end

  it "reste en taille md par défaut" do
    render_inline(described_class.new(user: build(:user)))

    expect(page.find("span, div")[:class]).to include("h-10", "w-10")
  end
end
