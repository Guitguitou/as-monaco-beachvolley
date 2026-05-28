# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:user) { create(:user) }

  before do
    login_as(user, scope: :user)
  end

  describe "GET /profile" do
    it "returns http success" do
      get profile_path
      expect(response).to have_http_status(:success)
    end

    it "displays user balance" do
      create(:credit_transaction, user: user, amount: 1000)
      get profile_path
      expect(response.body).to include("1000")
    end

    context "when user is a coach" do
      let(:user) { create(:user, :coach, salary_per_training_cents: 5000) }

      it "displays coach salary information" do
        create(:session, :entrainement, user: user, start_at: 1.week.ago)
        get profile_path
        expect(response).to have_http_status(:success)
      end

      it "displays trainings tab data" do
        create(:session, :entrainement, user: user, start_at: 1.week.ago)
        get profile_path, params: { tab: 'trainings' }
        expect(response).to have_http_status(:success)
      end
    end
  end
end
