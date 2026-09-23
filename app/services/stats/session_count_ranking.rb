# frozen_string_literal: true

module Stats
  # Classe des joueurs par nombre d'inscriptions valides, à égalité le premier
  # inscrit passe devant. Sans `sessions`, toutes les sessions comptent.
  class SessionCountRanking
    def initialize(user_ids:, sessions: nil)
      @user_ids = user_ids
      @sessions = sessions
    end

    def top(limit = 3)
      rows(limit)
    end

    def ordered_user_ids
      return [] if @user_ids.empty?

      registrations.count.keys.map(&:first)
    end

    def full
      rows(nil).map.with_index(1) { |row, rank| { rank: rank, **row } }
    end

    private

    def rows(limit)
      return [] if @user_ids.empty?

      counts = registrations.limit(limit).pluck("users.id", "users.first_name", "users.last_name", "COUNT(registrations.id)")
      users = User.where(id: counts.map(&:first)).index_by(&:id)
      counts.map do |user_id, first_name, last_name, count|
        { user: users.fetch(user_id), count: count, name: "#{first_name} #{last_name}".strip }
      end
    end

    def registrations
      scope = Registration.valid.joins(:user).where(users: { id: @user_ids }).where.not(users: { last_name: "Test" })
      scope = scope.where(session_id: @sessions.select(:id)) if @sessions
      scope
        .group("users.id", "users.first_name", "users.last_name")
        .order(Arel.sql("COUNT(registrations.id) DESC, MIN(registrations.created_at) ASC"))
    end
  end
end
