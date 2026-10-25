# frozen_string_literal: true

require "rails_helper"

RSpec.describe AlertComponent, type: :component do
  it "annonce une erreur aux lecteurs d'écran" do
    render_inline(described_class.new(tone: :error, title: "2 erreurs")) { "Nom manquant" }

    expect(page).to have_css("div[role=alert].bg-red-50", text: "Nom manquant")
    expect(page).to have_css("h3.text-red-800", text: "2 erreurs")
  end

  it "reste discret pour un avertissement" do
    render_inline(described_class.new(tone: :warning)) { "Plus que 2 places" }

    expect(page).to have_css("div[role=status].bg-amber-50", text: "Plus que 2 places")
    expect(page).not_to have_css("h3")
  end

  it "garde les attributs HTML passés" do
    render_inline(described_class.new(tone: :info, data: { turbo_cache: "false" })) { "Info" }

    expect(page).to have_css("div[data-turbo-cache='false']")
  end
end
