# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Coach::Trainings", type: :request do
  let(:coach) { create(:user, :coach, activated_at: Time.current) }
  let(:admin) { create(:user, :admin, activated_at: Time.current) }

  describe "GET /coach/trainings" do
    context "when user is a coach" do
      before do
        login_as(coach, scope: :user)
      end

      it "returns http success" do
        get coach_trainings_path
        expect(response).to have_http_status(:success)
      end

      it "shows library tab by default" do
        get coach_trainings_path
        expect(response).to have_http_status(:success)
      end

      it "shows my_trainings tab when requested" do
        create(:session, :entrainement, user: coach, start_at: 1.week.ago)
        get coach_trainings_path, params: { tab: 'my_trainings' }
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is an admin" do
      before do
        login_as(admin, scope: :user)
      end

      it "returns http success" do
        get coach_trainings_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is not a coach or admin" do
      let(:regular_user) { create(:user, activated_at: Time.current) }

      before do
        login_as(regular_user, scope: :user)
      end

      it "redirects with alert" do
        get coach_trainings_path
        expect(response).to have_http_status(:redirect)
        expect(flash[:alert]).to include("Accès réservé")
      end
    end

    context "when user is not authenticated" do
      it "redirects to sign in" do
        get coach_trainings_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
