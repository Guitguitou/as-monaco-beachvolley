# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::ShopProducts", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:product) { create(:shop_product, name: "T-shirt Varone") }

  it "refuse l'accès à un joueur" do
    sign_in create(:user)
    get admin_shop_products_path

    expect(response).to redirect_to(root_path)
  end

  context "en tant qu'admin" do
    before { sign_in admin }

    it "liste les articles avec leurs coupes et leurs prix" do
      create(:shop_cut, product: product, label: "Femme", price_cents: 1400)

      get admin_shop_products_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("T-shirt Varone", "Femme", "14,00")
    end

    it "crée un article puis renvoie vers sa fiche pour ajouter coupes et coloris" do
      post admin_shop_products_path, params: { shop_product: { name: "Parka", brand: "Joma" } }

      created = Shop::Product.find_by!(name: "Parka")
      expect(response).to redirect_to(edit_admin_shop_product_path(created))
    end

    it "réaffiche le formulaire quand l'article est invalide" do
      post admin_shop_products_path, params: { shop_product: { name: "", brand: "" } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "affiche la fiche d'un article avec ses coupes et ses coloris" do
      create(:shop_cut, product: product, label: "Unisexe")
      create(:shop_color, product: product, name: "Noir", hex: "#232323")

      get edit_admin_shop_product_path(product)

      expect(response.body).to include("Unisexe", "Noir")
    end

    it "retire un article de la vente" do
      patch admin_shop_product_path(product), params: { shop_product: { active: "0" } }

      expect(product.reload).not_to be_active
      expect(response).to redirect_to(edit_admin_shop_product_path(product))
    end

    describe "coupes" do
      it "ajoute une coupe avec son prix en euros et ses tailles" do
        post admin_shop_product_shop_cuts_path(product),
             params: { shop_cut: { label: "Femme", price_eur: "14", sizes_text: "S, M, L" } }

        cut = Shop::Cut.of(product).sole
        expect([ cut.label, cut.price_cents, cut.sizes ]).to eq([ "Femme", 1400, %w[S M L] ])
        expect(response).to redirect_to(edit_admin_shop_product_path(product, anchor: "coupes"))
      end

      it "signale une coupe invalide sans l'enregistrer" do
        post admin_shop_product_shop_cuts_path(product), params: { shop_cut: { label: "", price_eur: "", sizes_text: "" } }

        expect(Shop::Cut.of(product)).to be_empty
        expect(flash[:alert]).to be_present
      end

      it "modifie puis supprime une coupe" do
        cut = create(:shop_cut, product: product)

        patch admin_shop_product_shop_cut_path(product, cut), params: { shop_cut: { price_eur: "20" } }
        expect(cut.reload.price_cents).to eq(2000)

        delete admin_shop_product_shop_cut_path(product, cut)
        expect(Shop::Cut.of(product)).to be_empty
      end
    end

    describe "coloris" do
      it "ajoute un coloris avec sa photo" do
        photo = fixture_file_upload("avatar.png", "image/png")

        post admin_shop_product_shop_colors_path(product),
             params: { shop_color: { name: "Rouge", hex: "#e21e22", photo: photo } }

        color = Shop::Color.of(product).sole
        expect(color.photo).to be_attached
        expect(response).to redirect_to(edit_admin_shop_product_path(product, anchor: "coloris"))
      end

      it "supprime un coloris" do
        color = create(:shop_color, product: product)

        delete admin_shop_product_shop_color_path(product, color)

        expect(Shop::Color.of(product)).to be_empty
      end
    end
  end
end
