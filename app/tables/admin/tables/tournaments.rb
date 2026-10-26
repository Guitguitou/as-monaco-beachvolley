# frozen_string_literal: true

module Admin
  module Tables
    # Tournois de l'admin.
    class Tournaments < DataTable::Definition
      def columns
        [
          DataTable::Column.new(key: :title, label: "Titre", sort: "tournaments.title"),
          DataTable::Column.new(key: :starts_on, label: "Dates", sort: "tournaments.starts_on",
                                filter: DataTable::Filters::DateRange.new("tournaments.starts_on")),
          DataTable::Column.new(key: :level, label: "Niveau", sort: "tournaments.level",
                                filter: DataTable::Filters::Select.new("tournaments.level",
                                                                       options: Tournament::LEVELS.map { |level| [ level, level ] })),
          DataTable::Column.new(key: :payment, label: "Paiement")
        ]
      end

      def search_columns = %w[tournaments.title]

      def quick_filters
        [ DataTable::QuickFilter.new(key: :upcoming, label: "À venir",
                                     scope: ->(tournaments) { tournaments.where(ends_on: Date.current..) }) ]
      end

      def default_order = { starts_on: :desc }
    end
  end
end
