# frozen_string_literal: true

module Admin
  module Tables
    # Tournois de l'admin.
    class Tournaments < DataTable::Definition
      def columns
        [
          col(:title, "Titre", sort: "tournaments.title"),
          date_col(:starts_on, "Dates", "tournaments.starts_on"),
          col(:level, "Niveau", sort: "tournaments.level",
                                filter: select_filter("tournaments.level", Tournament::LEVELS.map { |level| [ level, level ] })),
          col(:payment, "Paiement")
        ]
      end

      def search_columns = %w[tournaments.title]

      def quick_filters = [ upcoming ]

      def default_order = { starts_on: :desc }
    end
  end
end
