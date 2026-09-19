require 'rails_helper'

RSpec.describe "Packs", type: :request do
  describe "GET /packs" do
    it "returns http success" do
      get packs_path
      expect(response).to have_http_status(:success)
    end

    it "n’affiche hors connexion que les packs marqués publics" do
      public_pack = create(:pack, :licence, name: "Licence publique", public: true)
      private_pack = create(:pack, :licence, name: "Licence réservée", public: false)

      get packs_path

      expect(response.body).to include(public_pack.name)
      expect(response.body).not_to include(private_pack.name)
    end

    it "affiche à un membre activé les packs que ses droits autorisent" do
      pack = create(:pack, :credits, name: "Pack crédits", public: false)
      login_as(create(:user, activated_at: Time.current), scope: :user)

      get packs_path

      expect(response.body).to include(pack.name)
    end
  end

  describe "POST /packs/:id/buy" do
    let(:pack) { create(:pack, :licence, public: true, active: true, amount_cents: 5000) }

    it "asks guest identity before creating payment when signed out" do
      expect do
        post buy_pack_path(pack)
      end.not_to change(CreditPurchase, :count)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Finaliser l'achat")
    end

    it "creates a user and a credit purchase then renders the redirect page" do
      allow_any_instance_of(User).to receive(:send_reset_password_instructions)

      expect do
        with_env("SHERLOCK_GATEWAY" => "fake", "SHERLOCK_API_KEY" => "test_secret") do
          post buy_pack_path(pack), params: {
            guest: { email: "guest@example.com", first_name: "Jean", last_name: "Dupont" }
          }
        end
      end.to change(User, :count).by(1).and change(CreditPurchase, :count).by(1)

      purchase = CreditPurchase.last
      expect(purchase.user).to be_present
      expect(purchase.pack).to eq(pack)
      expect(purchase.amount_cents).to eq(5000)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("text/html")
    end

    # Avant, la bascule vers LCL passait par une page blanche brute, sans
    # marque ni recours si le script ne partait pas.
    it "annonce la redirection et laisse un bouton de secours" do
      user = create(:user, activated_at: Time.current)
      login_as(user, scope: :user)

      with_env("SHERLOCK_GATEWAY" => "real", "SHERLOCK_API_KEY" => "test_secret",
               "SHERLOCK_MERCHANT_ID" => "TEST_MERCHANT") do
        post buy_pack_path(pack)
      end

      expect(response.body).to include("Redirection en cours")
      expect(response.body).to include(pack.name)
      expect(response.body).to include(Sherlock::RealGateway::DEFAULT_INIT_URL)
      expect(response.body).to include("Continuer vers le paiement")
      expect(response.body).to include('name="Data"', 'name="Seal"', 'name="InterfaceVersion"')
      expect(response.body).to include('document.getElementById("sherlock-payment").submit()')
    end

    it "renvoie vers la boutique quand la passerelle échoue" do
      user = create(:user, activated_at: Time.current)
      login_as(user, scope: :user)
      allow(Sherlock::CreatePayment).to receive(:new).and_raise(StandardError, "gateway down")

      post buy_pack_path(pack)

      expect(response).to redirect_to(packs_path)
      expect(flash[:alert]).to include("gateway down")
    end

    it "refuse l’achat d’un pack désactivé" do
      inactive_pack = create(:pack, :licence, public: true, active: false)

      expect { post buy_pack_path(inactive_pack) }.not_to change(CreditPurchase, :count)

      expect(response).to redirect_to(packs_path)
      expect(flash[:alert]).to include("n'est plus disponible")
    end

    it "demande la connexion pour un pack non public" do
      private_pack = create(:pack, :licence, public: false, active: true)

      post buy_pack_path(private_pack)

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to include("Connecte-toi")
    end

    it "réaffiche le formulaire quand l’identité invitée est invalide" do
      expect do
        post buy_pack_path(pack), params: {
          guest: { email: "pas-un-email", first_name: "Jean", last_name: "Dupont" }
        }
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Finaliser l'achat")
    end

    it "redirects to login when email already exists" do
      create(:user, email: "existing@example.com")

      post buy_pack_path(pack), params: {
        guest: { email: "existing@example.com", first_name: "Jean", last_name: "Dupont" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Cet email a déjà un compte")
    end
  end
end
