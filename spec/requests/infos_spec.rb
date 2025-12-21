# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Infos", type: :request do
  describe "GET /infos" do
    it "returns http success" do
      get infos_root_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /infos/videos" do
    it "returns http success" do
      get infos_videos_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /infos/planning-entrainements" do
    it "returns http success" do
      get infos_planning_trainings_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /infos/planning-saison" do
    it "returns http success" do
      get infos_planning_season_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /infos/reglement-interieur" do
    it "returns http success" do
      get infos_internal_rules_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /infos/responsables-reservations" do
    it "returns http success" do
      get infos_reservations_leads_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /infos/plaquette-presentation" do
    it "returns http success" do
      get infos_brochure_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /infos/regles-inscription" do
    it "returns http success" do
      get infos_registration_rules_path
      expect(response).to have_http_status(:success)
    end
  end
end
