require "rails_helper"

# Inscription depuis une carte de la grille : la réponse remplace la carte et la
# zone de flash, sans rediriger — le joueur ne perd pas sa position de scroll.
RSpec.describe "Registrations depuis une carte", type: :request do
  let(:coach) { create(:user, :coach, activated_at: Time.current) }
  let(:level) { create(:level) }
  let(:player) { create(:user, level: level, activated_at: Time.current) }
  let(:session_record) do
    create(:session, session_type: "entrainement", terrain: "Terrain 1", user: coach, levels: [ level ])
  end

  before do
    create(:credit_transaction, user: player, amount: 1_000)
    travel_to(Time.zone.parse("2025-06-10 10:00"))
    sign_in player, scope: :user
  end

  after { travel_back }

  describe "POST avec from=card" do
    it "répond en Turbo Stream et remplace la carte et le flash" do
      post session_registrations_path(session_record), params: { from: "card" }, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<turbo-stream")
      expect(response.body).to include("session_card_#{session_record.id}")
      expect(response.body).to include('target="flash"')
      expect(response.body).to include("Inscription réussie")
    end

    it "rend la carte dans son nouvel état, avec l'action de désinscription" do
      post session_registrations_path(session_record), params: { from: "card" }, as: :turbo_stream

      expect(response.body).to include("Je me désinscris")
      expect(response.body).not_to include("Je m&#39;inscris")
    end

    it "affiche le refus métier dans le flash au lieu de le perdre" do
      # Délai des 17h dépassé : le contrôleur refuse et doit le dire.
      travel_to(session_record.start_at.change(hour: 18))

      post session_registrations_path(session_record), params: { from: "card" }, as: :turbo_stream

      expect(response.body).to include("Les inscriptions sont closes")
      expect(player.reload.registrations).to be_empty
    end
  end

  describe "DELETE avec from=card" do
    before { post session_registrations_path(session_record), params: { from: "card" }, as: :turbo_stream }

    it "répond en Turbo Stream et repropose l'inscription" do
      delete session_registration_path(session_record, id: "current"),
             params: { from: "card" }, as: :turbo_stream

      expect(response.body).to include("<turbo-stream")
      expect(response.body).to include("Désinscription réussie")
      expect(response.body).to include("session_card_#{session_record.id}")
      expect(player.reload.registrations).to be_empty
    end
  end

  describe "sans from=card" do
    it "redirige toujours vers la fiche session" do
      post session_registrations_path(session_record)

      expect(response).to redirect_to(session_path(session_record))
      expect(flash[:notice]).to include("Inscription réussie")
    end
  end
end
