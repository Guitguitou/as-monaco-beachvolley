# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Me::Sessions", type: :request do
  let(:user) { create(:user) }
  let(:session_record) { create(:session, :jeu_libre) }
  let(:registration) { create(:registration, user: user, session: session_record, status: :confirmed) }

  before do
    sign_in user
  end

  describe "GET /me/sessions" do
    it "returns http success" do
      get me_sessions_path
      expect(response).to have_http_status(:success)
    end

    it "shows upcoming sessions" do
      future_session = create(:session, :jeu_libre, start_at: 1.week.from_now)
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
    it "returns http success" do
      get me_session_path(registration.session)
      expect(response).to have_http_status(:success)
    end

    it "only shows sessions the user is registered for" do
      other_session = create(:session, :jeu_libre)
      
      expect {
        get me_session_path(other_session)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end

