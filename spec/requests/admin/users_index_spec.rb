# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Users#index", type: :request do
  let(:admin) { create(:user, :admin, last_name: "Admin") }
  let!(:zoe) { create(:user, first_name: "Zoé", last_name: "Arnaud", license_type: "competition") }
  let!(:marc) { create(:user, first_name: "Marc", last_name: "Blanc", license_type: "libre") }

  before { login_as(admin, scope: :user) }

  it "affiche le tableau filtré selon l'URL" do
    get admin_users_path(f: { license_type: "libre" })

    expect(response).to have_http_status(:success)
    expect(response.body).to include("Blanc Marc").and include("Réinitialiser")
    expect(response.body).not_to include("Arnaud Zoé")
  end

  it "exporte en CSV les joueurs filtrés" do
    get admin_users_path(format: :csv, q: "arnaud")

    expect(response.media_type).to eq("text/csv")
    expect(response.headers["Content-Disposition"]).to include("joueurs-")
    expect(response.body).to include("Arnaud Zoé")
    expect(response.body).not_to include("Blanc Marc")
  end
end
