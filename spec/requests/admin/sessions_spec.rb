# frozen_string_literal: true

require 'rails_helper'

RSpec.xdescribe "Admin::Sessions", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/admin/sessions/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/admin/sessions/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/admin/sessions/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get "/admin/sessions/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/admin/sessions/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/admin/sessions/show"
      expect(response).to have_http_status(:success)
    end
  end
end

# Test for DuplicateSessionService integration
RSpec.describe DuplicateSessionService, type: :service do
  let(:admin_user) { create(:user, :admin) }
  let(:session) { create(:session, user: admin_user) }

  it "can be called from controller context" do
    result = DuplicateSessionService.new(session, 2).call

    expect(result[:success]).to be true
    expect(result[:created_count]).to eq(2)
    expect(result[:created_sessions].count).to eq(2)
  end
end
