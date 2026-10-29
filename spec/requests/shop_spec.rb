# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Boutique équipements", type: :request do
  let(:user) { create(:user, activated_at: Time.current) }
  let(:product) { create(:shop_product, name: "T-shirt Varone") }
  let!(:cut) { create(:shop_cut, product: product, label: "Femme", price_cents: 1800, sizes: %w[S M L]) }
  let!(:color) { create(:shop_color, product: product, name: "Noir") }

  before { sign_in user }

  context "sans campagne ouverte" do
    it "annonce que les commandes sont fermées" do
      get shop_products_path

      expect(response.body).to include("Les commandes d&#39;équipements sont fermées")
      expect(response.body).not_to include("T-shirt Varone")
    end

    it "refuse d'ajouter au panier" do
      post shop_cart_lines_path, params: { line: { cut_id: cut.id, color_id: color.id, size: "M" } }

      expect(response).to redirect_to(shop_products_path)
      expect(Shop::Order.count).to eq(0)
    end
  end

  context "pendant une campagne" do
    let!(:campaign) { create(:shop_campaign, welcome_message: "Commande groupée Joma et Nine") }

    it "réserve la boutique aux licenciés à jour" do
      sign_in create(:user, activated_at: nil)

      get shop_products_path
      expect(response).to redirect_to(packs_path)

      post shop_cart_lines_path, params: { line: { cut_id: cut.id, color_id: color.id, size: "M" } }
      expect(Shop::Order.count).to eq(0)

      get packs_path
      expect(response.body).not_to include("Commande groupée d'équipements ouverte")
    end

    it "annonce la commande groupée sur la page Boutique" do
      get packs_path

      expect(response.body).to include("Commande groupée d'équipements ouverte")
    end

    it "présente les articles en vente qui ont coupes et coloris" do
      create(:shop_product, name: "Article sans coupe")
      create(:shop_product, name: "Article retiré", active: false)

      get shop_products_path

      expect(response.body).to include("T-shirt Varone", "Commande groupée Joma et Nine", "18,00")
      expect(response.body).not_to include("Article sans coupe", "Article retiré")
    end

    it "affiche la fiche d'un article avec ses tailles et son guide" do
      cut.update!(size_guide: create(:shop_size_guide, name: "Nine femme"))

      get shop_product_path(product)

      expect(response.body).to include("T-shirt Varone", "Noir", "Guide des tailles", "Nine femme")
    end

    it "ajoute au panier au prix de la coupe, même si le formulaire en annonce un autre" do
      post shop_cart_lines_path, params: { line: { cut_id: cut.id, color_id: color.id, size: "M", quantity: 2, unit_price_cents: 1 } }

      expect(response).to redirect_to(shop_cart_path)
      expect(Shop::Order.cart_for(user, campaign).total_cents).to eq(3600)
    end

    it "renvoie vers la fiche avec le motif quand la taille manque" do
      post shop_cart_lines_path, params: { line: { cut_id: cut.id, color_id: color.id, size: "" } }

      expect(response).to redirect_to(shop_product_path(product))
      expect(flash[:alert]).to eq("Choisis une taille de la liste.")
    end

    describe "panier" do
      let(:order) { create(:shop_order, user: user, campaign: campaign) }
      let!(:line) { create(:shop_order_line, order: order, cut: cut, product: product, product_name: "T-shirt Varone", quantity: 1) }

      it "affiche les lignes et le total" do
        get shop_cart_path

        expect(response.body).to include("T-shirt Varone", "18,00")
      end

      it "change la quantité puis retire la ligne" do
        patch shop_cart_line_path(line), params: { quantity: 3 }
        expect(line.reload.quantity).to eq(3)

        delete shop_cart_line_path(line)
        expect(order.lines).to be_empty
      end

      it "ne touche pas au panier d'un autre membre" do
        other_line = create(:shop_order_line, order: create(:shop_order, campaign: campaign))

        delete shop_cart_line_path(other_line)

        expect(response).to have_http_status(:not_found)
        expect(other_line.reload).to be_persisted
      end
    end
  end
end
