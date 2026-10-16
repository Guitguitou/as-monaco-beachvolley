# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Serveur MCP", type: :request do
  let(:application) do
    Doorkeeper::Application.create!(name: "Claude", redirect_uri: "https://claude.ai/api/mcp/auth_callback", scopes: "read")
  end
  let(:admin) { create(:user, :admin, first_name: "Ada", last_name: "Admin") }

  def token_for(user, scopes: "read", expires_in: 1.hour)
    Doorkeeper::AccessToken.create!(application:, resource_owner_id: user.id, scopes:, expires_in:).plaintext_token
  end

  def mcp(payload, token: token_for(admin))
    headers = { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json, text/event-stream" }
    headers["Authorization"] = "Bearer #{token}" if token
    post "/mcp", params: payload.to_json, headers: headers
  end

  def call_tool(name, arguments = {}, **options)
    mcp({ jsonrpc: "2.0", id: 1, method: "tools/call", params: { name:, arguments: } }, **options)
    response.parsed_body.fetch("result")
  end

  describe "authentification" do
    it "refuse une requête sans jeton avec un challenge pointant vers les métadonnées" do
      mcp({ jsonrpc: "2.0", id: 1, method: "tools/list" }, token: nil)

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["WWW-Authenticate"]).to match(%r{resource_metadata="http://[^/]+/\.well-known/oauth-protected-resource/mcp"})
    end

    it "refuse un jeton expiré" do
      token = token_for(admin, expires_in: 1.hour)
      travel 2.hours do
        mcp({ jsonrpc: "2.0", id: 1, method: "tools/list" }, token:)
      end

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to eq("invalid_token")
    end

    it "refuse un jeton révoqué" do
      token = token_for(admin)
      Mcp::Connections.new.revoke_for(admin)
      mcp({ jsonrpc: "2.0", id: 1, method: "tools/list" }, token:)

      expect(response).to have_http_status(:unauthorized)
    end

    it "refuse un joueur même avec un jeton valide" do
      mcp({ jsonrpc: "2.0", id: 1, method: "tools/list" }, token: token_for(create(:user)))

      expect(response).to have_http_status(:forbidden)
    end

    it "coupe l'accès dès que l'utilisateur perd son rôle Staff" do
      token = token_for(admin)
      admin.update!(admin: false)
      mcp({ jsonrpc: "2.0", id: 1, method: "tools/list" }, token:)

      expect(response).to have_http_status(:forbidden)
    end

    it "coupe l'accès d'un compte désactivé" do
      token = token_for(admin)
      admin.disable!
      mcp({ jsonrpc: "2.0", id: 1, method: "tools/list" }, token:)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "protocole" do
    it "répond à l'initialisation" do
      mcp({ jsonrpc: "2.0", id: 1, method: "initialize",
            params: { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "claude", version: "1" } } })

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("result", "serverInfo", "name")).to eq("as-monaco-beach-volley")
    end

    it "accepte les notifications sans réponse" do
      mcp({ jsonrpc: "2.0", method: "notifications/initialized" })

      expect(response).to have_http_status(:accepted)
    end

    it "liste uniquement des tools en lecture seule" do
      mcp({ jsonrpc: "2.0", id: 1, method: "tools/list" })

      tools = response.parsed_body.dig("result", "tools")
      expect(tools.map { |tool| tool["name"] }).to contain_exactly(
        "list_sessions", "list_players", "get_player", "list_level_groups", "list_tournaments", "list_stages", "club_stats"
      )
      expect(tools.map { |tool| tool.dig("annotations", "readOnlyHint") }).to all(be(true))
    end

    it "refuse les requêtes GET (serveur sans état)" do
      get "/mcp"

      expect(response).to have_http_status(:method_not_allowed)
    end
  end

  describe "tools" do
    let(:level) { create(:level, name: "G2") }

    it "list_sessions renvoie le remplissage des sessions de la période" do
      session = create(:session, max_players: 4, start_at: 1.day.from_now.change(hour: 18))
      session.levels << level
      Registration.new(session:, user: create(:user), status: :confirmed).save!(validate: false)
      Registration.new(session:, user: create(:user), status: :waitlisted).save!(validate: false)

      result = call_tool("list_sessions", { level_id: level.id })

      expect(result["isError"]).to be(false)
      sessions = result.dig("structuredContent", "sessions")
      expect(sessions.size).to eq(1)
      expect(sessions.first).to include("id" => session.id, "confirmed_count" => 1, "waitlisted_count" => 1, "places_left" => 3,
                                        "levels" => [ "G2 M" ])
    end

    it "list_sessions signale une date invalide" do
      result = call_tool("list_sessions", { from: "demain" })

      expect(result["isError"]).to be(true)
      expect(result.dig("content", 0, "text")).to include("Date invalide")
    end

    it "list_players filtre par solde et n'expose pas les coordonnées" do
      poor = create(:user, first_name: "Paul", last_name: "Pauvre")
      poor.balance.update!(amount: 100)
      create(:user, first_name: "Rita", last_name: "Riche").balance.update!(amount: 5000)

      players = call_tool("list_players", { balance_below: 400 }).dig("structuredContent", "players")

      expect(players.map { |player| player["name"] }).to include("Paul Pauvre")
      expect(players.map { |player| player["name"] }).not_to include("Rita Riche")
      expect(players.first.keys).not_to include("email")
    end

    it "get_player renvoie le parcours du joueur" do
      player = create(:user)
      session = create(:session)
      Registration.new(session:, user: player, status: :confirmed).save!(validate: false)

      result = call_tool("get_player", { id: player.id })["structuredContent"]

      expect(result["registrations"].first).to include("session_id" => session.id, "status" => "confirmed")
      expect(result).not_to have_key("email")
    end

    it "get_player signale un joueur introuvable" do
      expect(call_tool("get_player", { id: 0 })["isError"]).to be(true)
    end

    it "list_level_groups regroupe les joueurs actifs par niveau" do
      player = create(:user, first_name: "Léa", last_name: "Ligue")
      UserLevel.create!(user: player, level:)

      groups = call_tool("list_level_groups").dig("structuredContent", "groups")

      expect(groups).to include(a_hash_including("level_id" => level.id, "members_count" => 1))
    end

    it "list_tournaments et list_stages répondent" do
      expect(call_tool("list_tournaments")["isError"]).to be(false)
      expect(call_tool("list_stages")["isError"]).to be(false)
    end

    it "club_stats compte l'activité de la période" do
      create(:session, start_at: Date.current.beginning_of_month.in_time_zone.change(hour: 10))

      stats = call_tool("club_stats", { from: Date.current.beginning_of_month.iso8601 })["structuredContent"]

      expect(stats["sessions_by_type"]).to eq("entrainement" => 1)
    end

    context "en tant que responsable financier" do
      let(:financial_manager) { create(:user, :financial_manager) }

      it "accède aux statistiques" do
        result = call_tool("club_stats", {}, token: token_for(financial_manager))

        expect(result["isError"]).to be(false)
      end

      it "n'accède pas aux joueurs, comme dans l'app" do
        result = call_tool("list_players", {}, token: token_for(financial_manager))

        expect(result["isError"]).to be(true)
        expect(result.dig("content", 0, "text")).to include("Accès refusé")
      end
    end
  end
end
