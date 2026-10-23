# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::ClubRules", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:player) { create(:user, activated_at: 1.year.ago) }
  let(:valid_params) do
    {
      entrainement_price_euros: "4,50", jeu_libre_price_euros: "3", coaching_prive_price_euros: "15",
      stage_price_euros: "0", priority_window_hours: "12", registration_deadline_hour: "16",
      registration_opening_days: "5", cancellation_deadline_mode: "hours_before",
      cancellation_deadline_hour: "22", cancellation_hours_before: "8"
    }
  end

  describe "GET /admin/regles-du-club" do
    it "affiche les règles en euros pour un admin" do
      login_as(admin, scope: :user)

      get admin_club_rules_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Règles du club", 'value="4.00"', "S&#39;applique aux nouvelles séances",
                                       "Immédiat, toutes les séances")
    end

    it "refuse un joueur" do
      login_as(player, scope: :user)

      get admin_club_rules_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /admin/regles-du-club" do
    it "enregistre les règles, prix convertis en centimes" do
      login_as(admin, scope: :user)

      patch admin_club_rules_path, params: { club_rules: valid_params }

      expect(response).to redirect_to(admin_club_rules_path)
      setting = ClubSetting.current
      expect(setting.price_by_type).to eq("entrainement" => 450, "jeu_libre" => 300, "coaching_prive" => 1500, "stage" => 0)
      expect([ setting.priority_window_hours, setting.registration_deadline_hour, setting.registration_opening_days ])
        .to eq([ 12, 16, 5 ])
      expect([ setting.cancellation_deadline_mode, setting.cancellation_hours_before ]).to eq([ "hours_before", 8 ])
    end

    it "réaffiche le formulaire avec les erreurs si la saisie est invalide" do
      login_as(admin, scope: :user)

      patch admin_club_rules_path,
            params: { club_rules: valid_params.merge(jeu_libre_price_euros: "abc", registration_deadline_hour: "25") }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Les règles n'ont pas été enregistrées")
      expect(ClubSetting.current.registration_deadline_hour).to eq(17)
    end

    it "refuse un joueur" do
      login_as(player, scope: :user)

      patch admin_club_rules_path, params: { club_rules: valid_params }

      expect(response).to redirect_to(root_path)
      expect(ClubSetting.current.registration_deadline_hour).to eq(17)
    end
  end
end
