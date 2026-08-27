require "rails_helper"

RSpec.describe "Mon terrain (accueil joueur)", type: :request do
  let(:coach) { create(:user, :coach, activated_at: Time.current) }
  let(:level) { create(:level) }
  let(:player) { create(:user, level: level, activated_at: Time.current) }

  before do
    create(:credit_transaction, user: player, amount: 1_000)
    travel_to(Time.zone.parse("2025-06-10 10:00"))
  end

  after { travel_back }

  it "exige une connexion" do
    get home_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "rend l'écran avec la navbar applicative, pas le layout public" do
    sign_in player, scope: :user
    get home_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include("Mon terrain")
    # Le layout public n'a pas de navigation applicative.
    expect(response.body).to include(sessions_path)
  end

  it "affiche le solde de crédits" do
    sign_in player, scope: :user
    get home_path

    expect(response.body).to include("Tes crédits")
    expect(response.body).to include("1 000")
  end

  context "sans session à venir" do
    it "propose d'aller voir les sessions ouvertes" do
      sign_in player, scope: :user
      get home_path

      expect(response.body).to include("Rien de prévu")
      expect(response.body).to include("Voir les sessions ouvertes")
    end
  end

  context "avec une session à venir" do
    let!(:session_record) do
      create(:session, session_type: "entrainement", terrain: "Terrain 1",
                       user: coach, levels: [ level ],
                       start_at: Time.zone.parse("2025-06-12 19:00"),
                       end_at: Time.zone.parse("2025-06-12 20:30"))
    end

    before { create(:registration, user: player, session: session_record) }

    it "met la prochaine session en tête avec son compte à rebours" do
      sign_in player, scope: :user
      get home_path

      expect(response.body).to include("Ta prochaine session")
      expect(response.body).to include("dans 2 jours")
      expect(response.body).not_to include("Rien de prévu")
    end
  end

  describe "après connexion" do
    it "atterrit sur Mon terrain et non sur les classements" do
      post user_session_path, params: { user: { email: player.email, password: "password123" } }

      expect(response).to redirect_to(home_path)
    end

    it "envoie un compte non activé vers la boutique" do
      inactive = create(:user, activated_at: nil)
      post user_session_path, params: { user: { email: inactive.email, password: "password123" } }

      expect(response).to redirect_to(packs_path)
    end
  end
end
