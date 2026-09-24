# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::Levels", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:player) { create(:user) }
  let!(:level) { create(:level, name: "G2") }

  describe "Authentication" do
    it "redirects to login when not authenticated" do
      get admin_levels_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context "as a player" do
    before { sign_in player }

    it "redirects index with an alert" do
      get admin_levels_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Accès interdit")
    end

    it "cannot create a level" do
      expect {
        post admin_levels_path, params: { level: { name: "G9", gender: "mixed", color: "#000000" } }
      }.not_to change(Level, :count)
      expect(response).to redirect_to(root_path)
    end

    it "cannot update a level" do
      patch admin_level_path(level), params: { level: { name: "Hacked" } }
      expect(level.reload.name).to eq("G2")
      expect(response).to redirect_to(root_path)
    end

    it "cannot destroy a level" do
      expect {
        delete admin_level_path(level)
      }.not_to change(Level, :count)
      expect(response).to redirect_to(root_path)
    end
  end

  context "as an admin" do
    before { sign_in admin }

    it "lists levels" do
      get admin_levels_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("G2")
    end

    it "shows a level" do
      get admin_level_path(level)
      expect(response).to have_http_status(:success)
    end

    it "renders the new form" do
      get new_admin_level_path
      expect(response).to have_http_status(:success)
    end

    it "renders the edit form" do
      get edit_admin_level_path(level)
      expect(response).to have_http_status(:success)
    end

    it "creates a level" do
      expect {
        post admin_levels_path, params: { level: { name: "G3", gender: "female", color: "#123456" } }
      }.to change(Level, :count).by(1)
      expect(response).to redirect_to(admin_levels_path)
    end

    it "updates a level" do
      patch admin_level_path(level), params: { level: { name: "G4" } }
      expect(level.reload.name).to eq("G4")
      expect(response).to redirect_to(admin_levels_path)
    end

    it "destroys a level" do
      expect {
        delete admin_level_path(level)
      }.to change(Level, :count).by(-1)
      expect(response).to redirect_to(admin_levels_path)
    end
  end
end
