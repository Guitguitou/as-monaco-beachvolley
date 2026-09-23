# frozen_string_literal: true

module Stats
  # Classe des joueurs du plus inactif au plus actif, d'après la date de leur
  # dernière session valide. Ceux qui n'ont jamais joué n'ont pas de durée
  # d'inactivité : ils passent en tête seulement si `include_never_played`.
  class InactivityRanking
    def initialize(user_ids:, timezone:, include_never_played: false)
      @user_ids = user_ids
      @timezone = timezone
      @include_never_played = include_never_played
    end

    def top(limit = 3)
      return [] if @user_ids.empty?

      (never_played + played).first(limit)
    end

    private

    def played
      users = User.where(id: last_sessions.keys).index_by(&:id)
      last_sessions.sort_by { |_user_id, last_session_at| last_session_at }.map do |user_id, last_session_at|
        row(users.fetch(user_id), last_session_at, days_since(last_session_at))
      end
    end

    def never_played
      return [] unless @include_never_played

      real_users.where.not(id: last_sessions.keys).map { |user| row(user, nil, nil) }
    end

    def last_sessions
      @last_sessions ||= Registration.valid.joins(:session).where(user_id: real_users.select(:id))
        .group(:user_id).maximum("sessions.start_at")
    end

    def real_users
      User.where(id: @user_ids).where.not(last_name: "Test")
    end

    def days_since(time)
      ((@timezone.now - time.in_time_zone(@timezone)) / 1.day).round
    end

    def row(user, last_session_at, days_since)
      { user: user, last_session_at: last_session_at, days_since: days_since, name: user.full_name }
    end
  end
end
