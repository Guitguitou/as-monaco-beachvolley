# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Checkout", type: :request do
  let(:secret) { "test_secret" }
  let(:seal) { Sherlock::Seal.new(secret: secret) }
  let(:user) { create(:user, activated_at: Time.current) }
  let(:pack) { create(:pack, :credits, name: "Pack 10 €", credits: 1000) }
  let(:purchase) do
    create(:credit_purchase, user: user, pack: pack, credits: 1000,
                             amount_cents: 1000, sherlock_transaction_reference: "REF-123")
  end

  def sherlock_data(**fields)
    fields.map { |key, value| "#{key}=#{value}" }.join("|")
  end

  def post_return(data, seal_value: nil, path: checkout_return_path)
    with_env("SHERLOCK_API_KEY" => secret, "SHERLOCK_SEAL_ALGO" => nil) do
      post path, params: { Data: data, Seal: seal_value || seal.compute(data) }
    end
  end

  describe "POST /checkout/return" do
    before { purchase }

    # Le cœur du correctif : LCL revient en POST cross-site, sans cookie de
    # session. Le résultat est donc lu dans la réponse signée, puis on redirige
    # vers un GET où la session est de nouveau disponible.
    context "avec une réponse acceptée" do
      let(:data) { sherlock_data(transactionReference: "REF-123", responseCode: "00", amount: 1000) }

      it "crédite l’achat sans attendre le webhook" do
        expect { post_return(data) }
          .to change { purchase.reload.status }.from("pending").to("paid")
      end

      # L'identifiant est signé et daté : il porte le récapitulatif sans
      # dépendre d'une session, que LCL vient justement de faire perdre.
      it "redirige vers un récapitulatif signé qui désigne cet achat" do
        post_return(data)

        signed_id = response.headers["Location"][%r{/checkout/(.+)\z}, 1]

        expect(CreditPurchase.find_signed!(signed_id, purpose: CheckoutController::SIGNED_ID_PURPOSE))
          .to eq(purchase)
      end

      it "borne la validité du récapitulatif dans le temps" do
        post_return(data)
        location = response.headers["Location"]

        travel_to(CheckoutController::SIGNED_ID_TTL.from_now + 1.minute) { get location }

        expect(response).to redirect_to(packs_path)
      end

      it "affiche la confirmation même sans session, comme au retour de LCL" do
        post_return(data)
        follow_redirect!

        expect(response.body).to include("Paiement réussi")
        expect(response.body).to include("Pack 10 €")
        expect(response.body).to include("REF-123")
      end

      it "affiche les crédits ajoutés et le nouveau solde" do
        post_return(data)
        follow_redirect!

        expect(response.body).to include("+ 1000")
        expect(response.body).to include(user.reload.balance.amount.to_s)
      end

      # La régression la plus visible : un membre non-admin était renvoyé vers
      # /admin/payments, qui le rejetait avec « Accès interdit ».
      it "n’envoie pas un membre non-admin sur une page d’administration" do
        login_as(user, scope: :user)

        post_return(data)
        follow_redirect!

        expect(response.body).to include("Paiement réussi")
        expect(response.body).not_to include("Accès interdit")
      end
    end

    context "avec un refus de la banque" do
      let(:data) { sherlock_data(transactionReference: "REF-123", responseCode: "05") }

      it "marque l’achat en échec" do
        expect { post_return(data) }
          .to change { purchase.reload.status }.from("pending").to("failed")
      end

      it "affiche un refus, et non une réussite" do
        post_return(data)
        follow_redirect!

        expect(response.body).to include("Paiement refusé")
        expect(response.body).not_to include("Paiement réussi")
      end

      it "affiche le motif transmis par la banque" do
        post_return(data)
        follow_redirect!

        expect(response.body).to include("Autorisation refusée")
      end

      it "propose de réessayer le même pack" do
        post_return(data)
        follow_redirect!

        expect(response.body).to include(buy_pack_path(pack))
      end
    end

    context "avec une annulation du client" do
      let(:data) { sherlock_data(transactionReference: "REF-123", responseCode: "17") }

      it "marque l’achat annulé" do
        expect { post_return(data) }
          .to change { purchase.reload.status }.from("pending").to("cancelled")
      end

      it "affiche l’annulation" do
        post_return(data)
        follow_redirect!

        expect(response.body).to include("Paiement annulé")
      end
    end

    context "avec un sceau invalide" do
      let(:data) { sherlock_data(transactionReference: "REF-123", responseCode: "00") }

      it "ne touche pas à l’achat" do
        expect { post_return(data, seal_value: "faux_sceau") }
          .not_to change { purchase.reload.status }
      end

      it "renvoie vers la boutique avec une alerte" do
        post_return(data, seal_value: "faux_sceau")

        expect(response).to redirect_to(packs_path)
        expect(flash[:alert]).to include("vérifier ce retour de paiement")
      end
    end

    context "avec une référence inconnue" do
      let(:data) { sherlock_data(transactionReference: "REF-INCONNUE", responseCode: "00") }

      it "renvoie vers la boutique avec une alerte" do
        post_return(data)

        expect(response).to redirect_to(packs_path)
        expect(flash[:alert]).to include("vérifier ce retour de paiement")
      end
    end

    # SHERLOCK_RETURN_URL_SUCCESS peut encore pointer sur l'ancienne URL en
    # production : elle doit continuer de fonctionner.
    context "sur l’ancienne URL de retour" do
      let(:data) { sherlock_data(transactionReference: "REF-123", responseCode: "00") }

      it "traite le retour de la même façon" do
        expect { post_return(data, path: checkout_success_path) }
          .to change { purchase.reload.status }.to("paid")
      end
    end
  end

  describe "GET /checkout/:id" do
    def signed_id_for(record)
      record.signed_id(purpose: CheckoutController::SIGNED_ID_PURPOSE)
    end

    it "affiche l’attente quand la banque n’a encore rien confirmé" do
      get checkout_path(signed_id_for(purchase))

      expect(response.body).to include("Paiement en cours")
      expect(response.body).to include("REF-123")
    end

    it "reste accessible sans être connecté, pour les achats invités" do
      purchase.update!(status: :paid, paid_at: Time.current)

      get checkout_path(signed_id_for(purchase))

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Paiement réussi")
    end

    it "refuse un identifiant forgé" do
      get checkout_path("nimporte-quoi")

      expect(response).to redirect_to(packs_path)
      expect(flash[:alert]).to include("n'est plus valable")
    end

    it "refuse un identifiant signé pour un autre usage" do
      get checkout_path(purchase.signed_id(purpose: :autre_chose))

      expect(response).to redirect_to(packs_path)
    end

    it "refuse un identifiant expiré" do
      signed_id = purchase.signed_id(purpose: CheckoutController::SIGNED_ID_PURPOSE, expires_in: 1.hour)

      travel_to(2.hours.from_now) { get checkout_path(signed_id) }

      expect(response).to redirect_to(packs_path)
    end

    it "refuse l’identifiant d’un achat supprimé" do
      signed_id = signed_id_for(purchase)
      purchase.destroy!

      get checkout_path(signed_id)

      expect(response).to redirect_to(packs_path)
    end
  end
end
