# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Terrains", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:player) { create(:user, activated_at: 1.year.ago) }
  let!(:first) { create(:terrain, name: "Terrain 1", position: 1, color: "ocean") }
  let!(:second) { create(:terrain, name: "Terrain 2", position: 2, color: "ink") }

  before { login_as(admin, scope: :user) }

  it "liste les terrains actifs puis archivés" do
    create(:terrain, name: "Ancien", position: 3, archived_at: 1.day.ago)

    get admin_terrains_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include("Terrains actifs", "Terrains archivés", "Ancien", "bg-terrain-ocean")
  end

  it "crée un terrain en dernière position avec une couleur libre" do
    post admin_terrains_path, params: { terrain: { name: "Terrain 3", color: "" } }

    expect(response).to have_http_status(:unprocessable_content)

    post admin_terrains_path, params: { terrain: { name: "Terrain 3", color: "green" } }

    expect(response).to redirect_to(admin_terrains_path)
    expect(Terrain.find_by(name: "Terrain 3")).to have_attributes(position: 3, color: "green")
  end

  it "propose la première couleur libre dans le formulaire" do
    get new_admin_terrain_path

    expect(response.body).to match(/value="gold"[^>]*checked|checked[^>]*value="gold"/)
  end

  it "refuse une couleur hors palette" do
    patch admin_terrain_path(first), params: { terrain: { color: "#123456" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(first.reload.color).to eq("ocean")
  end

  it "renomme un terrain" do
    patch admin_terrain_path(first), params: { terrain: { name: "Central", color: "teal" } }

    expect(first.reload).to have_attributes(name: "Central", color: "teal")
  end

  it "échange les positions avec les flèches" do
    patch move_admin_terrain_path(second, direction: "up")

    expect([ first.reload.position, second.reload.position ]).to eq([ 2, 1 ])

    patch move_admin_terrain_path(second, direction: "up")

    expect(second.reload.position).to eq(1)
  end

  it "archive puis réactive un terrain" do
    patch archive_admin_terrain_path(first)
    expect(first.reload).to be_archived

    patch unarchive_admin_terrain_path(first)
    expect(first.reload).not_to be_archived
  end

  it "supprime un terrain sans historique" do
    expect { delete admin_terrain_path(second) }.to change(Terrain, :count).by(-1)
  end

  it "refuse de supprimer un terrain qui a un historique" do
    create(:terrain_closure, terrain: second)

    get admin_terrains_path
    expect(response.body).to include("a un historique : archivez-le")

    expect { delete admin_terrain_path(second) }.not_to change(Terrain, :count)
    expect(flash[:alert]).to include("archivez-le")
  end

  it "refuse un joueur" do
    login_as(player, scope: :user)

    get admin_terrains_path

    expect(response).to redirect_to(root_path)
  end
end
