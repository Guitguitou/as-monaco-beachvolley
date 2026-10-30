# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Paiement de la boutique équipements", type: :request do
  let(:secret) { "test_secret" }
  let(:user) { create(:user, activated_at: Time.current) }
  let(:campaign) { create(:shop_campaign) }
  let(:order) { create(:shop_order, user: user, campaign: campaign) }
  let!(:line) { create(:shop_order_line, order: order, quantity: 2, unit_price_cents: 1800, size: "M") }

  before { sign_in user }

  def pay_with(response_code)
    purchase = CreditPurchase.find_by!(shop_order_id: order.id)
    data = "transactionReference=#{purchase.sherlock_transaction_reference}|responseCode=#{response_code}|amount=#{purchase.amount_cents}"
    with_env("SHERLOCK_API_KEY" => secret, "SHERLOCK_SEAL_ALGO" => nil) do
      post checkout_return_path, params: { Data: data, Seal: Sherlock::Seal.new(secret: secret).compute(data) }
    end
    follow_redirect!
  end

  it "envoie vers la page de paiement avec le montant des lignes" do
    post checkout_shop_cart_path

    expect(response.body).to include("Commande d&#39;équipements", "36,00")
    expect(CreditPurchase.find_by!(shop_order_id: order.id).amount_cents).to eq(3600)
    expect(order.reload).to be_awaiting_payment_status
  end

  it "confirme la commande payée au retour de la banque" do
    post checkout_shop_cart_path
    pay_with("00")

    expect(response).to redirect_to(shop_order_path(order))
    follow_redirect!
    expect(response.body).to include("Commande payée", order.reload.number)
  end

  it "rend le panier quand le paiement est refusé" do
    post checkout_shop_cart_path
    pay_with("05")

    expect(response).to redirect_to(shop_cart_path)
    follow_redirect!
    expect(response.body).to include("Payer 36,00")
    expect(order.reload).to be_cart_status
  end

  it "permet d'annuler un paiement resté en cours" do
    post checkout_shop_cart_path

    get shop_cart_path
    expect(response.body).to include("Un paiement est en cours")

    delete payment_shop_cart_path
    expect(order.reload).to be_awaiting_payment_status
    get shop_cart_path
    expect(order.reload).to be_cart_status
  end

  describe "Mes commandes" do
    before { order.mark_paid! }

    it "liste et affiche les commandes payées" do
      get shop_orders_path
      expect(response.body).to include(order.number)

      get shop_order_path(order)
      expect(response.body).to include("Total payé", "36,00")
    end

    it "corrige une taille jusqu'à la clôture, au même prix" do
      patch shop_order_line_path(line), params: { size: "L" }

      expect(line.reload.size).to eq("L")
      expect(line.unit_price_cents).to eq(1800)
    end

    it "refuse une correction quand la campagne n'autorise pas les modifications" do
      campaign.update!(allow_edits: false)

      patch shop_order_line_path(line), params: { size: "L" }

      expect(line.reload.size).to eq("M")
      expect(flash[:alert]).to eq("La commande ne peut plus être modifiée.")
    end

    it "ne montre pas la commande d'un autre membre" do
      sign_in create(:user)

      get shop_order_path(order)

      expect(response).to have_http_status(:not_found)
    end
  end
end
