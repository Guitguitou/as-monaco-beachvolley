# frozen_string_literal: true

module Terrains
  # Échange la position d'un terrain avec son voisin (flèches haut / bas de
  # l'admin). Le voisin est cherché parmi les terrains de même statut (actifs
  # ou archivés), comme ils sont listés dans l'admin.
  class Reorder
    DIRECTIONS = %w[up down].freeze

    def initialize(terrain)
      @terrain = terrain
    end

    def move(direction)
      return false unless DIRECTIONS.include?(direction)

      neighbour = find_neighbour(direction)
      return false unless neighbour

      Terrain.transaction do
        own, other = @terrain.position, neighbour.position
        # Positions égales (données anciennes) : on force un écart d'un cran.
        other += (direction == "up" ? -1 : 1) if own == other
        @terrain.update!(position: other)
        neighbour.update!(position: own)
      end
      true
    end

    private

    def find_neighbour(direction)
      scope = @terrain.archived? ? Terrain.where.not(archived_at: nil) : Terrain.active
      terrains = scope.ordered.to_a
      index = terrains.index(@terrain)
      neighbour_index = direction == "up" ? index - 1 : index + 1
      return if neighbour_index.negative?

      terrains[neighbour_index]
    end
  end
end
