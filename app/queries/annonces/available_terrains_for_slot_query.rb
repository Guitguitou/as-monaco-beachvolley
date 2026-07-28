module Annonces
  # Terrains libres pour un créneau donné : ni chevauchés par une session
  # existante (même formule d'overlap que Sessions::OverlappingOnTerrainQuery),
  # ni fermés à cette date (TerrainClosure). Retourne les clés d'enum
  # (« Terrain 1 », …) utilisables telles quelles pour Session#terrain.
  class AvailableTerrainsForSlotQuery
    def self.call(slot:)
      new(slot: slot).call
    end

    def initialize(slot:)
      @slot = slot
    end

    def call
      Session.terrains.keys.reject { |terrain| occupied?(terrain) || closed?(terrain) }
    end

    private

    attr_reader :slot

    def occupied?(terrain)
      Session.where(terrain: terrain)
             .where("start_at < ? AND end_at > ?", slot.end_at, slot.start_at)
             .exists?
    end

    def closed?(terrain)
      TerrainClosure.covers?(terrain: terrain, date: slot.start_at.to_date)
    end
  end
end
