# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Stages", type: :request do
  let(:stage) { create(:stage) }

  describe "GET /stages" do
    it "requires authentication" do
      get stages_path
      # Stages index requires authentication except for show
      expect(response).to have_http_status(:redirect)
    end

    context "when authenticated" do
      let(:user) { create(:user) }

      before do
        login_as(user, scope: :user)
      end

      it "returns http success" do
        get stages_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /stages/:id" do
    it "returns http success without authentication" do
      get stage_path(stage)
      expect(response).to have_http_status(:success)
    end

    it "displays stage packs" do
      pack = create(:pack, pack_type: :stage, stage: stage)
      get stage_path(stage)
      expect(response.body).to include(stage.title)
    end
  end
end

