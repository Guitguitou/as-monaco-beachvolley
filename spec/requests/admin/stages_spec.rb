# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Admin::Stages", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:stage) { create(:stage) }

  before do
    login_as(admin, scope: :user)
  end

  describe "GET /admin/stages" do
    it "returns http success" do
      get admin_stages_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/stages/:id" do
    it "returns http success" do
      get admin_stage_path(stage)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/stages/new" do
    it "returns http success" do
      get new_admin_stage_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/stages" do
    let(:valid_params) do
      {
        stage: {
          title: "Stage d'été",
          description: "Description du stage",
          starts_on: Date.tomorrow,
          ends_on: Date.tomorrow + 7.days,
          price: 50000
        }
      }
    end

    it "creates a new stage" do
      expect {
        post admin_stages_path, params: valid_params
      }.to change { Stage.count }.by(1)
    end

    it "redirects to stage show page" do
      post admin_stages_path, params: valid_params
      expect(response).to redirect_to(admin_stage_path(Stage.last))
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          stage: {
            title: ""
          }
        }
      end

      it "renders new template" do
        post admin_stages_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /admin/stages/:id/edit" do
    it "returns http success" do
      get edit_admin_stage_path(stage)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/stages/:id" do
    let(:update_params) do
      {
        stage: {
          title: "Updated Title"
        }
      }
    end

    it "updates the stage" do
      patch admin_stage_path(stage), params: update_params
      expect(stage.reload.title).to eq("Updated Title")
    end

    it "redirects to stage show page" do
      patch admin_stage_path(stage), params: update_params
      expect(response).to redirect_to(admin_stage_path(stage))
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          stage: {
            title: ""
          }
        }
      end

      it "renders edit template" do
        patch admin_stage_path(stage), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end

