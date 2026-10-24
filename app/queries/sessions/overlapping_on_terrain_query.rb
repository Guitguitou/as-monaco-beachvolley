module Sessions
  class OverlappingOnTerrainQuery
    def self.call(session:)
      Session.held
             .where(terrain_id: session.terrain_id)
             .where.not(id: session.id)
             .where("start_at < ? AND end_at > ?", session.end_at, session.start_at)
    end
  end
end
