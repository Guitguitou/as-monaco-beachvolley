# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::Packs", type: :request do
  let(:admin) { create(:user, admin: true) }
  let(:regular_user) { create(:user, admin: false) }
  let(:stage) { create(:stage) }
  let(:pack) { create(:pack) }

  describe "Authentication" do
    it "redirects to login when not authenticated" do
      get admin_packs_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "denies access to non-admin users" do
      sign_in regular_user
      get admin_packs_path
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /admin/packs" do
    before { sign_in admin }

    it "returns http success" do
      get admin_packs_path
      expect(response).to have_http_status(:success)
    end

    it "displays packs" do
      pack
      get admin_packs_path
      expect(response.body).to include(pack.name)
    end
  end

  describe "GET /admin/packs/new" do
    before { sign_in admin }

    it "returns http success" do
      get new_admin_pack_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/packs" do
    before { sign_in admin }

    let(:valid_attributes) do
      {
        name: "Pack Test",
        description: "Description",
        pack_type: "credits",
        amount_cents: 5000,
        credits: 10,
        active: true
      }
    end

    it "creates a new pack" do
      expect {
        post admin_packs_path, params: { pack: valid_attributes }
      }.to change(Pack, :count).by(1)
    end

    it "redirects to index" do
      post admin_packs_path, params: { pack: valid_attributes }
      expect(response).to redirect_to(admin_packs_path)
    end
  end

  describe "GET /admin/packs/:id/edit" do
    before { sign_in admin }

    it "returns http success" do
      get edit_admin_pack_path(pack)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/packs/:id" do
    before { sign_in admin }

    it "updates the pack" do
      patch admin_pack_path(pack), params: { pack: { name: "Updated Name" } }
      expect(pack.reload.name).to eq("Updated Name")
    end

    it "redirects to index" do
      patch admin_pack_path(pack), params: { pack: { name: "Updated" } }
      expect(response).to redirect_to(admin_packs_path)
    end
  end

  describe "DELETE /admin/packs/:id" do
    before { sign_in admin }

    it "destroys the pack" do
      pack # create it first
      expect {
        delete admin_pack_path(pack)
      }.to change(Pack, :count).by(-1)
    end

    it "redirects to index" do
      delete admin_pack_path(pack)
      expect(response).to redirect_to(admin_packs_path)
    end
  end
end
