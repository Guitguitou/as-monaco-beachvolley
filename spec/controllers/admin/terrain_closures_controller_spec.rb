# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::TerrainClosuresController, type: :controller do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user, admin: false, activated_at: Time.current) }

  describe "GET #index" do
    context "when admin" do
      before do
        allow(controller).to receive(:current_user).and_return(admin)
        allow(controller).to receive(:user_signed_in?).and_return(true)
        allow(controller).to receive(:authenticate_user!).and_return(true)
      end

      it "returns success" do
        get :index
        expect(response).to have_http_status(:success)
      end
    end

    context "when not admin" do
      before do
        allow(controller).to receive(:current_user).and_return(regular_user)
        allow(controller).to receive(:user_signed_in?).and_return(true)
        allow(controller).to receive(:authenticate_user!).and_return(true)
      end

      it "redirects to root" do
        get :index
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST #create" do
    before do
      allow(controller).to receive(:current_user).and_return(admin)
      allow(controller).to receive(:user_signed_in?).and_return(true)
      allow(controller).to receive(:authenticate_user!).and_return(true)
    end

    it "creates a terrain closure" do
      expect {
        post :create, params: {
          terrain_closure: {
            terrain: "Terrain 1",
            starts_on: Date.new(2031, 1, 1),
            ends_on: Date.new(2031, 1, 3),
            reason: "Test"
          }
        }
      }.to change(TerrainClosure, :count).by(1)

      expect(response).to redirect_to(admin_terrain_closures_path)
    end
  end

  describe "DELETE #destroy" do
    let!(:closure) { create(:terrain_closure, terrain: "Terrain 2") }

    before do
      allow(controller).to receive(:current_user).and_return(admin)
      allow(controller).to receive(:user_signed_in?).and_return(true)
      allow(controller).to receive(:authenticate_user!).and_return(true)
    end

    it "destroys the closure" do
      expect {
        delete :destroy, params: { id: closure.id }
      }.to change(TerrainClosure, :count).by(-1)

      expect(response).to redirect_to(admin_terrain_closures_path)
    end
  end
end
