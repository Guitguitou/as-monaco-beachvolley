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
        "list_sessions", "list_players", "get_player", "list_level_groups", "list_tournaments", "list_stages", "club_stats",
        "list_purchases", "list_credit_transactions", "list_late_cancellations"
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

    it "list_sessions distingue coach et responsable de réservation, et montre les séances annulées" do
      lead = create(:user, :responsable, first_name: "Rita", last_name: "Resp")
      free_play = create(:session, :jeu_libre, user: lead, start_at: 1.day.from_now.change(hour: 18), end_at: 1.day.from_now.change(hour: 20))
      training = create(:session, start_at: 2.days.from_now.change(hour: 18))
      training.update!(cancelled_at: Time.current, cancellation_reason: "meteo")

      sessions = call_tool("list_sessions").dig("structuredContent", "sessions").index_by { |s| s["id"] }

      expect(sessions[free_play.id]).to include("responsable" => "Rita Resp", "cancelled" => false)
      expect(sessions[free_play.id]).not_to have_key("coach")
      expect(sessions[training.id]).to include("cancelled" => true, "cancellation_reason" => "meteo")
      expect(sessions[training.id]).to have_key("coach")
    end

    it "list_late_cancellations liste les désinscriptions tardives de la période, excusées comprises" do
      player = create(:user, first_name: "Paul", last_name: "Retard")
      training = create(:session, title: "Entraînement G2", start_at: 1.day.ago.change(hour: 18), end_at: 1.day.ago.change(hour: 20))
      counted = LateCancellation.create!(user: player, session: training)
      excused = LateCancellation.create!(user: create(:user), session: training, excused: true)
      LateCancellation.create!(user: player, session: create(:session, start_at: 10.days.ago, end_at: 10.days.ago + 2.hours))

      result = call_tool("list_late_cancellations", { from: 2.days.ago.to_date.iso8601, to: Date.current.iso8601 })

      rows = result.dig("structuredContent", "late_cancellations")
      expect(rows.map { |row| row["id"] }).to contain_exactly(counted.id, excused.id)
      expect(rows.find { |row| row["id"] == counted.id }).to include(
        "player" => "Paul Retard", "player_id" => player.id, "session_id" => training.id,
        "session_title" => "Entraînement G2", "excused" => false
      )
      expect(rows.find { |row| row["id"] == excused.id }["excused"]).to be(true)
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

    it "list_players pagine par curseur et filtre sur updated_since" do
      stub_const("Mcp::Tools::ListPlayers::MAX_RESULTS", 2)
      players = Array.new(3) { |i| create(:user, last_name: "Page#{i}") }
      players.each_with_index { |player, i| player.update_columns(updated_at: (10 - i).days.ago) }
      admin.update_columns(updated_at: 20.days.ago)

      first = call_tool("list_players")["structuredContent"]
      second = call_tool("list_players", { cursor: first["next_cursor"] })["structuredContent"]

      expect(first["players"].size).to eq(2)
      expect((first["players"] + second["players"]).map { |player| player["id"] }).to eq([ admin.id ] + players.map(&:id))
      expect(second["next_cursor"]).to be_nil

      # Seuil entre deux mises à jour : à 9 jours pile, la troncature à la
      # seconde de iso8601 rend le résultat dépendant du moment du run.
      recent = call_tool("list_players", { updated_since: (9.days + 12.hours).ago.iso8601 })["structuredContent"]
      expect(recent["players"].map { |player| player["id"] }).to eq(players.last(2).map(&:id))
    end

    it "get_player renvoie le parcours du joueur" do
      player = create(:user)
      session = create(:session)
      Registration.new(session:, user: player, status: :confirmed).save!(validate: false)

      result = call_tool("get_player", { id: player.id })["structuredContent"]

      expect(result["registrations"].first).to include("session_id" => session.id, "status" => "confirmed")
      expect(result).not_to have_key("email")
    end

it "list_players et get_player distinguent licence payée et dossier complet" do
      player = create(:user, first_name: "Dora", last_name: "Dossier", dossier_complet: false)

      listed = call_tool("list_players").dig("structuredContent", "players").find { |p| p["id"] == player.id }
      detail = call_tool("get_player", { id: player.id })["structuredContent"]

      expect(listed).to include("licence_payee" => true, "dossier_complet" => false)
      expect(detail).to include("licence_payee" => true, "dossier_complet" => false)
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

      it "accède aux achats, comme l'Historique achats" do
        expect(call_tool("list_purchases", {}, token: token_for(financial_manager))["isError"]).to be(false)
      end

      it "n'accède pas aux mouvements de crédits des joueurs" do
        expect(call_tool("list_credit_transactions", {}, token: token_for(financial_manager))["isError"]).to be(true)
      end
    end

    describe "list_purchases" do
      let(:player) { create(:user, first_name: "Paul", last_name: "Payeur") }
      let(:credits_pack) { create(:pack, name: "Carnet 10") }
      let(:licence_pack) { create(:pack, :licence, name: "Licence") }

      before do
        create(:credit_purchase, :paid, user: player, pack: credits_pack, amount_cents: 4000)
        create(:credit_purchase, :paid, user: player, pack: licence_pack, amount_cents: 15_000, credits: 0)
        create(:credit_purchase, :failed, user: player, pack: credits_pack, amount_cents: 4000)
        create(:credit_purchase, :paid, pack: credits_pack, amount_cents: 4000, created_at: 2.months.ago)
      end

      it "liste les achats du mois avec les totaux encaissés" do
        result = call_tool("list_purchases")["structuredContent"]

        expect(result["purchases"].size).to eq(3)
        expect(result["purchases"]).to include(a_hash_including("player" => "Paul Payeur", "pack" => "Licence", "amount_eur" => 150.0))
        expect(result["totals"]).to include("paid_eur" => 190.0,
                                            "paid_by_pack_type_eur" => { "credits" => 40.0, "licence" => 150.0 },
                                            "count_by_status" => { "paid" => 2, "failed" => 1 })
      end

      it "filtre par statut et type de pack" do
        result = call_tool("list_purchases", { status: "paid", pack_type: "licence" })["structuredContent"]

        expect(result["purchases"].map { |purchase| purchase["pack"] }).to eq([ "Licence" ])
      end

      it "pagine par curseur sans changer les totaux de la période" do
        stub_const("Mcp::Tools::ListPurchases::MAX_RESULTS", 2)

        first = call_tool("list_purchases")["structuredContent"]
        second = call_tool("list_purchases", { cursor: first["next_cursor"] })["structuredContent"]

        expect((first["purchases"] + second["purchases"]).map { |purchase| purchase["id"] }.uniq.size).to eq(3)
        expect(second["next_cursor"]).to be_nil
        expect(second["totals"]["paid_eur"]).to eq(190.0)
      end

      it "avec updated_since, liste les achats modifiés depuis, quelle que soit leur date de création" do
        old = CreditPurchase.find_by(created_at: ...1.month.ago)
        CreditPurchase.update_all(updated_at: 3.days.ago)
        old.update_columns(updated_at: 1.hour.ago)

        result = call_tool("list_purchases", { updated_since: 1.day.ago.iso8601 })["structuredContent"]

        expect(result["purchases"].map { |purchase| purchase["id"] }).to eq([ old.id ])
        expect(result).to include("from" => nil, "to" => nil)
      end
    end

    describe "list_credit_transactions" do
      let(:player) { create(:user, first_name: "Céline", last_name: "Crédit") }
      let(:session) { create(:session, title: "Entraînement G2") }

      before do
        create(:credit_transaction, user: player, transaction_type: :purchase, amount: 1000)
        create(:credit_transaction, user: player, session:, transaction_type: :training_payment, amount: -400)
        create(:credit_transaction, user: player, session:, transaction_type: :refund, amount: 400)
        create(:credit_transaction, user: player, transaction_type: :manual_adjustment, amount: 50, created_at: 2.months.ago)
      end

      it "liste les mouvements du mois avec les totaux par type" do
        result = call_tool("list_credit_transactions")["structuredContent"]

        expect(result["transactions"].size).to eq(3)
        expect(result["totals_by_type"]).to eq(
          "purchase" => { "count" => 1, "amount_credits" => 1000 },
          "training_payment" => { "count" => 1, "amount_credits" => -400 },
          "refund" => { "count" => 1, "amount_credits" => 400 }
        )
      end

      it "filtre par session et rattache la session au mouvement" do
        result = call_tool("list_credit_transactions", { session_id: session.id, transaction_type: "refund" })["structuredContent"]

        expect(result["transactions"].size).to eq(1)
        expect(result["transactions"].first).to include("player" => "Céline Crédit", "amount_credits" => 400)
        expect(result["transactions"].first["session"]).to include("title" => "Entraînement G2")
      end

      it "pagine par curseur" do
        stub_const("Mcp::Tools::ListCreditTransactions::MAX_RESULTS", 2)

        first = call_tool("list_credit_transactions")["structuredContent"]
        second = call_tool("list_credit_transactions", { cursor: first["next_cursor"] })["structuredContent"]

        expect((first["transactions"] + second["transactions"]).map { |transaction| transaction["id"] }.uniq.size).to eq(3)
        expect(second["next_cursor"]).to be_nil
      end

      it "avec updated_since, liste les mouvements modifiés depuis" do
        CreditTransaction.update_all(updated_at: 3.days.ago)
        recent = CreditTransaction.find_by(transaction_type: :refund)
        recent.update_columns(updated_at: 1.hour.ago)

        result = call_tool("list_credit_transactions", { updated_since: 1.day.ago.iso8601 })["structuredContent"]

        expect(result["transactions"].map { |transaction| transaction["id"] }).to eq([ recent.id ])
      end

      it "signale un curseur invalide" do
        result = call_tool("list_credit_transactions", { cursor: "abc" })

        expect(result["isError"]).to be(true)
        expect(result.dig("content", 0, "text")).to include("Curseur invalide")
      end
    end
  end
end
