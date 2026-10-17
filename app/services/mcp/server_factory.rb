# frozen_string_literal: true

module Mcp
  # Construit le serveur MCP exposé au Claude du Staff (cf. docs/adr/0001).
  class ServerFactory
    TOOLS = [
      Tools::ListSessions,
      Tools::ListPlayers,
      Tools::GetPlayer,
      Tools::ListLevelGroups,
      Tools::ListTournaments,
      Tools::ListStages,
      Tools::ClubStats,
      Tools::ListPurchases,
      Tools::ListCreditTransactions
    ].freeze

    INSTRUCTIONS = <<~TEXT
      Données du club de beach volley de l'AS Monaco, en lecture seule.
      Les crédits sont la monnaie interne du club (un entraînement en coûte 400) ;
      les montants en euros sont suffixés _eur. Les dates sont à l'heure de Paris.
      Les coordonnées des joueurs ne sont volontairement pas exposées.
    TEXT

    def self.build(context:)
      MCP::Server.new(
        name: "as-monaco-beach-volley",
        title: "AS Monaco Beach Volley",
        version: "1.0.0",
        instructions: INSTRUCTIONS,
        tools: TOOLS,
        server_context: context
      )
    end
  end
end
