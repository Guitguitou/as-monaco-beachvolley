module Sessions
  class OverlappingOnTerrainQuery
    def self.call(session:)
      Session.where(terrain: session.terrain)
             .where.not(id: session.id)
             .where("start_at < ? AND end_at > ?", session.end_at, session.start_at)
    end
  end
end
