# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Me::Sessions", type: :request do
  let(:user) { create(:user, activated_at: Time.current) }
  let(:session_record) { create(:session, :jeu_libre) }

  before do
    create(:credit_transaction, user: user, amount: 1000)
  end

  before do
    login_as(user, scope: :user)
  end

  describe "GET /me/sessions" do
    it "returns http success" do
      get me_sessions_path
      expect(response).to have_http_status(:success)
    end

    it "shows upcoming sessions" do
      future_session = create(:session, :jeu_libre, start_at: 1.week.from_now, end_at: 1.week.from_now + 90.minutes)
      create(:registration, user: user, session: future_session, status: :confirmed)

      get me_sessions_path
      expect(response).to have_http_status(:success)
    end

    it "shows past sessions" do
      past_session = create(:session, :jeu_libre, start_at: 1.week.ago, end_at: 1.week.ago + 90.minutes)
      create(:registration, user: user, session: past_session, status: :confirmed)

      get me_sessions_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /me/sessions/:id" do
    let(:registration) { create(:registration, user: user, session: session_record, status: :confirmed) }

    it "returns http success" do
      get me_session_path(registration.session)
      expect(response).to have_http_status(:success)
    end

    it "only shows sessions the user is registered for" do
      other_session = create(:session, :jeu_libre, terrain: 'Terrain 2')

      get me_session_path(other_session)
      expect(response).to have_http_status(:not_found)
    end
  end
end
