# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::PublicPages", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:script_url) { "https://script.google.com/macros/s/AKfycbw-abc_123/exec" }

  before { login_as(admin, scope: :user) }

  it "crée une page dont le slug est déduit du titre" do
    post admin_public_pages_path, params: { public_page: { title: "Tournoi d'été", slug: "", script_url: script_url } }

    expect(response).to redirect_to(admin_public_pages_path)
    expect(PublicPage.last).to have_attributes(slug: "tournoi-d-ete", script_url: script_url)

    get admin_public_pages_path
    expect(response.body).to include("/tournoi-d-ete")
  end

  it "refuse une URL hors Google Apps Script et un slug réservé" do
    post admin_public_pages_path, params: { public_page: { title: "X", slug: "admin", script_url: "https://evil.example/exec" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(PublicPage.count).to eq(0)
  end

  it "modifie puis supprime une page" do
    page = create(:public_page, slug: "inscriptions")

    patch admin_public_page_path(page), params: { public_page: { slug: "inscriptions-2026" } }
    expect(page.reload.slug).to eq("inscriptions-2026")

    delete admin_public_page_path(page)
    expect(PublicPage.count).to eq(0)
  end
end

RSpec.describe "PublicPages", type: :request do
  it "affiche le script dans une iframe sans connexion" do
    page = create(:public_page, title: "Inscriptions", slug: "inscriptions")

    get "/inscriptions"

    expect(response).to have_http_status(:success)
    expect(response.body).to include(%(<iframe src="#{page.script_url}"))
  end

  it "renvoie 404 pour un slug inconnu" do
    get "/inexistante"

    expect(response).to have_http_status(:not_found)
  end
end
