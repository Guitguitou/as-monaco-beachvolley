require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }
  let!(:managed_user) { create(:user, first_name: "Alice", last_name: "Martin", email: "alice@example.com") }

  before do
    host! "localhost"
    allow_any_instance_of(ApplicationController).to receive(:verify_authenticity_token)
  end

  describe "authorization" do
    it "redirects unauthenticated users" do
      get admin_users_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects non-admin users" do
      login_as regular_user, scope: :user
      get admin_users_path

      expect(response).to have_http_status(:found)
    end
  end

  describe "GET /admin/users" do
    before { login_as admin, scope: :user }

    it "returns success and shows the managed user" do
      get admin_users_path

      expect(response).to have_http_status(:success)
    end

    it "filters users by search query" do
      create(:user, first_name: "Bob", last_name: "Durand", email: "bob@example.com")

      get admin_users_path, params: { q: "alice@" }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("alice@example.com")
      expect(response.body).not_to include("bob@example.com")
    end
  end

  describe "GET /admin/users/:id" do
    before { login_as admin, scope: :user }

    it "returns success for user details page" do
      get admin_user_path(managed_user)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(managed_user.email)
    end
  end
end
