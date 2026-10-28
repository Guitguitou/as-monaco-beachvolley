# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::ShopSizeGuides", type: :request do
  before { sign_in create(:user, :admin) }

  it "liste les guides des tailles" do
    create(:shop_size_guide, name: "Nine femme")

    get admin_shop_size_guides_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include("Nine femme")
  end

  it "crée un guide à partir du tableau saisi en texte" do
    post admin_shop_size_guides_path,
         params: { shop_size_guide: { name: "Nine unisexe", measure_label: "Tour de hanches", rows_text: "S ; 92–96\nM ; 96–100" } }

    guide = Shop::SizeGuide.find_by!(name: "Nine unisexe")
    expect(guide.rows.pluck("size")).to eq(%w[S M])
    expect(response).to redirect_to(admin_shop_size_guides_path)
  end

  it "réaffiche le formulaire quand le tableau est vide" do
    post admin_shop_size_guides_path, params: { shop_size_guide: { name: "Vide", measure_label: "Tour", rows_text: "" } }

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "supprime un guide sans supprimer les coupes qui l'utilisaient" do
    guide = create(:shop_size_guide)
    cut = create(:shop_cut, size_guide: guide)

    delete admin_shop_size_guide_path(guide)

    expect(cut.reload.size_guide_id).to be_nil
  end
end
