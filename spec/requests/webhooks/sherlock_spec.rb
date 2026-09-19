# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Webhooks::Sherlock", type: :request do
  let(:secret) { "test_secret" }
  # Forme réelle des réponses du contrat : notre référence dans `orderId`,
  # celle générée par Sherlock's dans `transactionReference`.
  let(:data) { "orderId=REF-123|transactionReference=202607021135288e5b|responseCode=00" }

  before { allow(SherlockCallbackJob).to receive(:perform_later) }

  def post_webhook(params, algorithm: nil)
    with_env("SHERLOCK_API_KEY" => secret, "SHERLOCK_SEAL_ALGO" => algorithm) do
      post webhooks_sherlock_path, params: params
    end
  end

  def seal_for(data, algorithm: Sherlock::Seal::DEFAULT_ALGORITHM)
    Sherlock::Seal.new(secret: secret, algorithm: algorithm).compute(data)
  end

  describe "POST /webhooks/sherlock" do
    context "avec un sceau valide" do
      it "accuse réception" do
        post_webhook({ Data: data, Seal: seal_for(data) })

        expect(response).to have_http_status(:ok)
      end

      # Le traitement est asynchrone : la banque attend juste un accusé.
      it "confie la réponse au job de traitement" do
        expect(SherlockCallbackJob).to receive(:perform_later).with(
          hash_including("orderId" => "REF-123", "responseCode" => "00")
        )

        post_webhook({ Data: data, Seal: seal_for(data) })
      end

      it "rapproche l’achat sur notre référence, pas sur celle de LCL" do
        user = create(:user)
        pack = create(:pack, :credits, credits: 1000)
        purchase = create(:credit_purchase, user: user, pack: pack, credits: 1000,
                                            sherlock_transaction_reference: "REF-123")
        allow(SherlockCallbackJob).to receive(:perform_later) { |fields| Sherlock::HandleCallback.new(fields).call }

        post_webhook({ Data: data, Seal: seal_for(data) })

        expect(purchase.reload.status).to eq("paid")
      end
    end

    context "avec l’algorithme HMAC-SHA-256" do
      it "valide le sceau" do
        seal = seal_for(data, algorithm: Sherlock::Seal::HMAC_ALGORITHM)

        post_webhook({ Data: data, Seal: seal }, algorithm: Sherlock::Seal::HMAC_ALGORITHM)

        expect(response).to have_http_status(:ok)
      end
    end

    it "rejette une notification sans Data" do
      post_webhook({ Seal: seal_for(data) })

      expect(response).to have_http_status(:bad_request)
    end

    it "rejette une notification sans sceau" do
      post_webhook({ Data: data })

      expect(response).to have_http_status(:bad_request)
    end

    it "rejette une notification dont le sceau ne correspond pas" do
      post_webhook({ Data: data, Seal: "faux_sceau" })

      expect(response).to have_http_status(:unauthorized)
      expect(SherlockCallbackJob).not_to have_received(:perform_later)
    end

    context "quand le traitement lève une erreur" do
      before do
        allow(Sherlock::DataParser).to receive(:parse).and_raise(StandardError, "Parse error")
        allow(Rails.logger).to receive(:error)
      end

      it "répond 500 pour que la banque retente" do
        post_webhook({ Data: data, Seal: seal_for(data) })

        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end
end
