# frozen_string_literal: true

module Admin
  module Tables
    # Fermetures de terrain de l'admin.
    class TerrainClosures < DataTable::Definition
      def columns
        [
          DataTable::Column.new(key: :terrain, label: "Terrain",
                                filter: DataTable::Filters::Select.new("terrain_closures.terrain_id",
                                                                       options: Terrain.ordered.map { |terrain| [ terrain.name, terrain.id ] })),
          DataTable::Column.new(key: :starts_on, label: "Du", sort: "terrain_closures.starts_on",
                                filter: DataTable::Filters::DateRange.new("terrain_closures.starts_on")),
          DataTable::Column.new(key: :ends_on, label: "Au", sort: "terrain_closures.ends_on"),
          DataTable::Column.new(key: :reason, label: "Motif"),
          DataTable::Column.new(key: :actions, label: "", class_name: "w-24")
        ]
      end

      def search_columns = %w[terrain_closures.reason]

      def quick_filters
        [ DataTable::QuickFilter.new(key: :current, label: "En cours ou à venir",
                                     scope: ->(closures) { closures.where(ends_on: Date.current..) }) ]
      end

      def default_order = { starts_on: :desc, terrain_id: :asc }
    end
  end
end
