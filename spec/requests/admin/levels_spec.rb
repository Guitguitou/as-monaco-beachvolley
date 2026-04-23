require "rails_helper"

RSpec.describe "Admin::Levels", type: :request do
  let(:admin) { create(:user, :admin) }
  let!(:level) { create(:level, name: "G2", gender: "mixed", color: "#123456") }

  before do
    host! "localhost"
    allow_any_instance_of(ApplicationController).to receive(:verify_authenticity_token)
    login_as admin, scope: :user
  end

  describe "GET /admin/levels" do
    it "lists existing levels" do
      get admin_levels_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("G2")
    end
  end

  describe "POST /admin/levels" do
    let(:params) { { level: { name: "G3", gender: "female", color: "#AABBCC" } } }

    it "creates a level and redirects to index" do
      expect do
        post admin_levels_path, params: params
      end.to change(Level, :count).by(1)

      expect(response).to redirect_to(admin_levels_path)
      expect(Level.order(:created_at).last.name).to eq("G3")
    end
  end

  describe "PATCH /admin/levels/:id" do
    it "updates the level" do
      patch admin_level_path(level), params: { level: { name: "G2+" } }

      expect(response).to redirect_to(admin_levels_path)
      expect(level.reload.name).to eq("G2+")
    end
  end

  describe "DELETE /admin/levels/:id" do
    it "deletes the level" do
      expect do
        delete admin_level_path(level)
      end.to change(Level, :count).by(-1)

      expect(response).to redirect_to(admin_levels_path)
    end
  end
end
