# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::Dashboard", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:financial_manager) { create(:user, :financial_manager) }

  describe "GET /admin" do
    context "when user is admin" do
      before do
        login_as(admin, scope: :user)
      end

      it "returns http success" do
        get admin_root_path
        expect(response).to have_http_status(:success)
      end

      it "shows overview tab by default" do
        get admin_root_path
        expect(response).to have_http_status(:success)
      end

      it "shows sessions tab" do
        get admin_root_path, params: { tab: 'sessions' }
        expect(response).to have_http_status(:success)
      end

      it "shows finances tab" do
        get admin_root_path, params: { tab: 'finances' }
        expect(response).to have_http_status(:success)
      end

      it "shows packs tab" do
        get admin_root_path, params: { tab: 'packs' }
        expect(response).to have_http_status(:success)
      end

      it "shows coaches tab" do
        get admin_root_path, params: { tab: 'coaches' }
        expect(response).to have_http_status(:success)
      end

      it "shows alerts tab" do
        get admin_root_path, params: { tab: 'alerts' }
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is financial manager" do
      before do
        login_as(financial_manager, scope: :user)
      end

      it "returns http success" do
        get admin_root_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is not admin or financial manager" do
      let(:regular_user) { create(:user, activated_at: Time.current) }

      before do
        login_as(regular_user, scope: :user)
      end

      it "redirects with alert" do
        get admin_root_path
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to include("Accès non autorisé")
      end
    end

    context "when user is not authenticated" do
      it "redirects to sign in" do
        get admin_root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end

