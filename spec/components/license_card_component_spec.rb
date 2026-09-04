require "rails_helper"

RSpec.describe LicenseCardComponent, type: :component do
  context "quand la licence n'est pas réglée" do
    let(:user) { build(:user, activated_at: nil) }

    it "annonce la licence à régler et propose la boutique" do
      render_inline(described_class.new(user: user))

      expect(page).to have_text("Licence à régler")
      expect(page).to have_link("Régler ma licence", href: "/packs")
    end

    # /profile est l'une des rares pages ouvertes aux comptes non activés : le
    # lien doit sortir du turbo_frame des onglets.
    it "fait sortir le CTA du turbo_frame" do
      render_inline(described_class.new(user: user))

      expect(page.find_link("Régler ma licence")["data-turbo-frame"]).to eq("_top")
    end

    it "se distingue visuellement" do
      render_inline(described_class.new(user: user))

      expect(page).to have_css("div.border-asmbv-red")
    end

    it "n'affiche pas de date d'activation" do
      render_inline(described_class.new(user: user))

      expect(page).not_to have_text("Active depuis")
    end
  end

  context "quand la licence est active" do
    let(:user) { build(:user, activated_at: Time.zone.parse("2026-01-15 10:00")) }

    it "annonce la licence active et sa date" do
      render_inline(described_class.new(user: user))

      expect(page).to have_text("Licence active")
      expect(page).to have_text("Active depuis le 15 janvier 2026")
    end

    it "ne propose plus la boutique" do
      render_inline(described_class.new(user: user))

      expect(page).not_to have_link("Régler ma licence")
    end
  end

  context "avec un type de licence" do
    it "badge une licence libre" do
      render_inline(described_class.new(user: build(:user, activated_at: 1.day.ago, license_type: "libre")))

      expect(page).to have_text("Libre")
    end

    # La licence compétition ouvre les inscriptions 24 h avant les autres,
    # ce que rien n'indiquait au joueur.
    it "badge une licence compétition et explique la priorité" do
      render_inline(described_class.new(user: build(:user, activated_at: 1.day.ago, license_type: "competition")))

      expect(page).to have_text("Compétition")
      expect(page).to have_text("24 h avant")
    end

    it "n'affiche aucun badge de type quand il est vide" do
      render_inline(described_class.new(user: build(:user, activated_at: 1.day.ago, license_type: nil)))

      expect(page).not_to have_text("Compétition")
      expect(page).not_to have_text("Libre")
    end
  end

  context "quand la saison prochaine est réglée" do
    it "le signale" do
      user = build(:user, activated_at: 1.day.ago, next_season_renewed: true)
      render_inline(described_class.new(user: user))

      expect(page).to have_text("Saison prochaine réglée")
    end
  end
end
