require "rails_helper"

RSpec.describe FlashComponent, type: :component do
  it "ne rend rien quand il n'y a aucun message" do
    render_inline(described_class.new(flash: {}))

    expect(page).not_to have_css("div")
  end

  it "affiche un notice comme un succès" do
    render_inline(described_class.new(flash: { "notice" => "Inscription confirmée." }))

    expect(page).to have_text("Inscription confirmée.")
    expect(page).to have_css("[role='status']")
    expect(page).to have_css(".border-green-600")
  end

  it "affiche un alert comme une erreur" do
    render_inline(described_class.new(flash: { "alert" => "Les inscriptions sont closes." }))

    expect(page).to have_text("Les inscriptions sont closes.")
    expect(page).to have_css("[role='alert'][aria-live='assertive']")
    expect(page).to have_css(".border-asmbv-red")
  end

  it "affiche plusieurs messages simultanément" do
    render_inline(described_class.new(flash: { "notice" => "Crédits ajoutés.", "alert" => "Solde bas." }))

    expect(page).to have_text("Crédits ajoutés.")
    expect(page).to have_text("Solde bas.")
    expect(page).to have_css("[data-controller='flash']", count: 2)
  end

  it "fait disparaître automatiquement les succès mais pas les erreurs" do
    render_inline(described_class.new(flash: { "notice" => "OK" }))
    expect(page.find("[data-controller='flash']")["data-flash-auto-dismiss-value"]).to eq("true")

    render_inline(described_class.new(flash: { "alert" => "KO" }))
    expect(page.find("[data-controller='flash']")["data-flash-auto-dismiss-value"]).to eq("false")
  end

  it "ignore les clés de flash internes à Rails" do
    render_inline(described_class.new(flash: { "timedout" => true }))

    expect(page).not_to have_css("div")
  end

  it "ignore les messages vides" do
    render_inline(described_class.new(flash: { "notice" => "" }))

    expect(page).not_to have_css("div")
  end

  it "propose un bouton de fermeture accessible" do
    render_inline(described_class.new(flash: { "notice" => "OK" }))

    expect(page).to have_css("button[aria-label='Fermer le message'][data-action='click->flash#dismiss']")
  end

  it "accepte un ActionDispatch::Flash::FlashHash" do
    flash = ActionDispatch::Flash::FlashHash.new
    flash[:notice] = "Bienvenue"

    render_inline(described_class.new(flash: flash))

    expect(page).to have_text("Bienvenue")
  end
end
