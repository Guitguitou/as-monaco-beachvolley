module Registrations
  class ScheduleConflictQuery
    def self.call(user:, session:)
      user.sessions_registered
          .where("start_at < ? AND end_at > ?", session.end_at, session.start_at)
          .where.not(id: session.id)
    end
  end
end
