# frozen_string_literal: true

require "rails_helper"

RSpec.describe LandingSectionComponent, type: :component do
  it "affiche l'étiquette, le titre, le chapeau et le contenu" do
    render_inline(described_class.new(eyebrow: "Accès", title: "Venir à La Turbie", subtitle: "10 min de Monaco")) { "Contenu" }

    expect(page).to have_text("Accès")
    expect(page).to have_css("h2", text: "Venir à La Turbie")
    expect(page).to have_text("10 min de Monaco")
    expect(page).to have_text("Contenu")
  end

  it "applique le fond sombre" do
    render_inline(described_class.new(eyebrow: "X", title: "Y", tone: :dark)) { "" }

    expect(page).to have_css("section.bg-gray-950")
  end
end
