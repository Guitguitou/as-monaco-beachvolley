# frozen_string_literal: true

require "rails_helper"

RSpec.describe DossierPendingComponent, type: :component do
  before { ClubSetting.current.update!(membership_form_url: "https://forms.example.com/adhesion") }

  it "invite le joueur à compléter son dossier avec le lien du formulaire" do
    render_inline(described_class.new(user: build(:user, dossier_complet: false)))

    expect(page).to have_text("Licence payée, en attente de ton dossier")
    expect(page).to have_link(href: "https://forms.example.com/adhesion")
  end

  it "ne s'affiche pas quand le dossier est complet" do
    render_inline(described_class.new(user: build(:user, dossier_complet: true)))
    expect(page).not_to have_text("en attente de ton dossier")
  end

  it "ne s'affiche pas quand la licence n'est pas payée" do
    render_inline(described_class.new(user: build(:user, activated_at: nil, dossier_complet: false)))
    expect(page).not_to have_text("en attente de ton dossier")
  end
end
