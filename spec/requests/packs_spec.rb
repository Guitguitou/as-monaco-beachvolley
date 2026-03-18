require 'rails_helper'

RSpec.describe "Packs", type: :request do
  describe "GET /packs" do
    it "returns http success" do
      get packs_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /packs/:id/buy" do
    let(:pack) { create(:pack, :licence, public: true, active: true, amount_cents: 5000) }

    it "asks guest identity before creating payment when signed out" do
      expect do
        post buy_pack_path(pack)
      end.not_to change(CreditPurchase, :count)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Finaliser l’achat")
    end

    it "creates a user and a credit purchase then returns payment HTML" do
      payment_html = "<html><body>payment form</body></html>"
      creator = instance_double(Sherlock::CreatePayment, call: payment_html)
      allow(Sherlock::CreatePayment).to receive(:new).and_return(creator)
      allow_any_instance_of(User).to receive(:send_reset_password_instructions)

      expect do
        post buy_pack_path(pack), params: {
          guest: { email: "guest@example.com", first_name: "Jean", last_name: "Dupont" }
        }
      end.to change(User, :count).by(1).and change(CreditPurchase, :count).by(1)

      purchase = CreditPurchase.last
      expect(purchase.user).to be_present
      expect(purchase.pack).to eq(pack)
      expect(purchase.amount_cents).to eq(5000)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include("text/html")
      expect(response.body).to include("payment form")
    end

    it "redirects to login when email already exists" do
      create(:user, email: "existing@example.com")

      post buy_pack_path(pack), params: {
        guest: { email: "existing@example.com", first_name: "Jean", last_name: "Dupont" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Cet email existe déjà")
    end
  end

end
