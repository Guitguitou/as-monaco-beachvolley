# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Connexion OAuth du connecteur MCP", type: :request do
  let(:redirect_uri) { "https://claude.ai/api/mcp/auth_callback" }
  let(:application) { Doorkeeper::Application.create!(name: "Claude", redirect_uri:, scopes: "read") }
  let(:authorize_params) do
    { client_id: application.uid, redirect_uri:, response_type: "code", scope: "read",
      code_challenge: "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM", code_challenge_method: "S256" }
  end

  describe "métadonnées" do
    it "décrit la ressource protégée" do
      get "/.well-known/oauth-protected-resource/mcp"

      expect(response.parsed_body).to include("resource" => "http://test.host/mcp",
                                              "authorization_servers" => [ "http://test.host" ])
    end

    it "décrit le serveur d'autorisation avec PKCE S256" do
      get "/.well-known/oauth-authorization-server"

      expect(response.parsed_body).to include("authorization_endpoint" => "http://test.host/oauth/authorize",
                                              "code_challenge_methods_supported" => [ "S256" ])
    end
  end

  describe "autorisation" do
    it "envoie vers la connexion puis revient à l'autorisation" do
      get "/oauth/authorize", params: authorize_params
      expect(response).to redirect_to(new_user_session_path)

      admin = create(:user, :admin, password: "password123")
      post user_session_path, params: { user: { email: admin.email, password: "password123" } }

      expect(response.location).to start_with("http://test.host/oauth/authorize?")
    end

    it "affiche la demande d'autorisation au Staff" do
      sign_in create(:user, :admin)
      get "/oauth/authorize", params: authorize_params

      expect(response).to have_http_status(:ok)
    end

    it "refuse un joueur" do
      sign_in create(:user)
      get "/oauth/authorize", params: authorize_params

      expect(response).to have_http_status(:forbidden)
    end

    it "refuse une demande sans PKCE d'un client public" do
      application.update!(confidential: false)
      sign_in create(:user, :admin)
      get "/oauth/authorize", params: authorize_params.except(:code_challenge, :code_challenge_method)

      expect(response).not_to have_http_status(:ok)
    end
  end

  describe "connexions Claude dans l'admin" do
    let(:admin) { create(:user, :admin, first_name: "Ada", last_name: "Admin") }

    before do
      Doorkeeper::AccessToken.create!(application:, resource_owner_id: admin.id, scopes: "read", expires_in: 3600)
    end

    it "liste et révoque les connexions" do
      sign_in admin
      get admin_claude_connections_path
      expect(response.body).to include("Ada Admin")

      delete admin_claude_connection_path(admin)

      expect(Doorkeeper::AccessToken.where(revoked_at: nil)).to be_empty
    end

    it "est réservée aux admins" do
      sign_in create(:user, :financial_manager)
      get admin_claude_connections_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe Mcp::ExpireIdleTokensJob do
    it "révoque les connexions inutilisées depuis 30 jours" do
      user = create(:user, :admin)
      idle = Doorkeeper::AccessToken.create!(application:, resource_owner_id: user.id, scopes: "read", created_at: 31.days.ago)
      fresh = Doorkeeper::AccessToken.create!(application:, resource_owner_id: user.id, scopes: "read")

      described_class.perform_now

      expect(idle.reload).to be_revoked
      expect(fresh.reload).not_to be_revoked
    end
  end
end
