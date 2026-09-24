# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Passwords", type: :request do
  let(:user) { create(:user) }
  let(:token) { user.send_reset_password_instructions }

  describe "GET /users/password/edit" do
    it "points the form to the password update path without format" do
      get edit_user_password_path(reset_password_token: token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(action="#{user_password_path}"))
    end
  end

  describe "PUT /users/password" do
    it "updates the password and redirects" do
      put user_password_path, params: {
        user: { reset_password_token: token, password: "nouveau-mdp-123", password_confirmation: "nouveau-mdp-123" }
      }

      expect(response).to have_http_status(:see_other).or have_http_status(:found)
      expect(user.reload.valid_password?("nouveau-mdp-123")).to be(true)
    end
  end
end
