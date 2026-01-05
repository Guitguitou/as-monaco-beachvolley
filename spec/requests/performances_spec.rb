# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Performances", type: :request do
  let(:user) { create(:user, activated_at: Time.current) }

  before do
    login_as(user, scope: :user)
  end

  describe "GET /performances" do
    it "returns http success" do
      get performances_path
      expect(response).to have_http_status(:success)
    end

    it "displays the page title" do
      get performances_path
      expect(response.body).to include("Performances & Stats")
    end

    it "displays the subtitle" do
      get performances_path
      expect(response.body).to include("Les badges qui font transpirer")
    end

    it "displays section headers" do
      get performances_path
      expect(response.body).to include("Records all-time")
      expect(response.body).to include("Jeu libre")
      expect(response.body).to include("Entraînement")
      expect(response.body).to include("Le frigo")
    end

    context "with stats data" do
      let(:coach) { create(:user, :coach) }
      let(:male_level) { create(:level, gender: "male", name: "G1 M") }
      let(:female_level) { create(:level, gender: "female", name: "G1 F") }
      let(:male_player) { create(:user, first_name: "John", last_name: "Doe") }
      let(:female_player) { create(:user, first_name: "Alice", last_name: "Martin") }

      before do
        create(:user_level, user: male_player, level: male_level)
        create(:user_level, user: female_player, level: female_level)

        session = create(:session, :jeu_libre, start_at: 1.week.ago, end_at: 1.week.ago + 90.minutes, user: coach)
        create(:registration, user: male_player, session: session, status: :confirmed)
        create(:registration, user: female_player, session: session, status: :confirmed)
      end

      it "displays player names when stats are available" do
        get performances_path
        expect(response.body).to include("John Doe")
        expect(response.body).to include("Alice Martin")
      end
    end

    context "without stats data" do
      it "displays 'Aucune donnée' messages" do
        get performances_path
        expect(response.body).to include("Aucune donnée")
      end
    end
  end
end

