# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::Finances", type: :request do
  describe "GET /admin/finances" do
    context "when user is admin" do
      let(:admin) { create(:user, :admin) }

      before { login_as(admin, scope: :user) }

      it "shows the financial summary and the players table" do
        get admin_finances_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Évolution mensuelle du CA", "Sessions par joueur")
      end

      it "shows the players of the requested period" do
        get admin_finances_path, params: { period: "year", period_anchor: "2025" }

        expect(response).to have_http_status(:success)
        expect(assigns(:players_period).label).to eq("2025")
      end
    end

    context "when user is financial manager" do
      before { login_as(create(:user, :financial_manager), scope: :user) }

      it "returns http success" do
        get admin_finances_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is not admin or financial manager" do
      before { login_as(create(:user, activated_at: Time.current), scope: :user) }

      it "redirects with alert" do
        get admin_finances_path
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to include("Accès non autorisé")
      end
    end
  end
end
