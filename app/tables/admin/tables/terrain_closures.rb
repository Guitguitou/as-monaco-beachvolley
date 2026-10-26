# frozen_string_literal: true

module Admin
  module Tables
    # Fermetures de terrain de l'admin.
    class TerrainClosures < DataTable::Definition
      def columns
        [
          col(:terrain, "Terrain", filter: select_filter("terrain_closures.terrain_id", options_from(Terrain.ordered))),
          date_col(:starts_on, "Du", "terrain_closures.starts_on"),
          col(:ends_on, "Au", sort: "terrain_closures.ends_on"),
          col(:reason, "Motif"),
          col(:actions, "", class_name: "w-24")
        ]
      end

      def search_columns = %w[terrain_closures.reason]

      def quick_filters = [ upcoming("En cours ou à venir") ]

      def default_order = { starts_on: :desc, terrain_id: :asc }
    end
  end
end
