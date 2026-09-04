require "rails_helper"

RSpec.describe SectionHeaderComponent, type: :component do
  it "rend le titre en typographie display" do
    render_inline(described_class.new(title: "Mes stats"))

    expect(page).to have_css("h2.font-anton.uppercase", text: "Mes stats")
  end

  it "affiche le sous-titre quand il est fourni" do
    render_inline(described_class.new(title: "Mes stats", subtitle: "Depuis ton inscription"))

    expect(page).to have_text("Depuis ton inscription")
  end

  it "n'affiche pas de sous-titre quand il est absent" do
    render_inline(described_class.new(title: "Mes stats"))

    expect(page).not_to have_css("p")
  end

  it "rend le slot action" do
    render_inline(described_class.new(title: "J'encadre")) do |header|
      header.with_action { "Tout voir" }
    end

    expect(page).to have_text("Tout voir")
  end
end
