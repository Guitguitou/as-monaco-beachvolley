# frozen_string_literal: true

require "rails_helper"

RSpec.describe ButtonComponent, type: :component do
  it "rend un lien quand href est fourni" do
    render_inline(described_class.new(href: "/packs")) { "Voir les packs" }

    expect(page).to have_link("Voir les packs", href: "/packs")
  end

  it "rend un bouton sinon, en gardant ses attributs" do
    render_inline(described_class.new(type: "submit", data: { action: "x#y" })) { "Envoyer" }

    expect(page).to have_css("button[type=submit][data-action='x#y']", text: "Envoyer")
  end

  it "occupe toute la largeur avec full_width et ajoute les classes de l'appelant" do
    render_inline(described_class.new(full_width: true, class: "mt-auto")) { "OK" }

    expect(page).to have_css("button.w-full.mt-auto")
  end

  it "rend un formulaire button_to pour une méthode autre que GET" do
    render_inline(described_class.new(href: "/packs/1/buy", method: :post, data: { turbo: false })) { "Acheter" }

    expect(page).to have_css("form[action='/packs/1/buy'][method=post] button.bg-brand", text: "Acheter")
    expect(page).to have_css("button[data-turbo='false']")
  end

  it "dessine l'icône demandée" do
    render_inline(described_class.new(icon: :plus)) { "Ajouter" }

    expect(page).to have_css("svg path[stroke-linecap=round]")
  end
end
