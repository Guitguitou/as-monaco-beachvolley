# frozen_string_literal: true

module Stats
  class PerformanceDashboard
    def initialize(timezone: "Europe/Paris")
      @timezone = ActiveSupport::TimeZone[timezone]
    end

    def call
      {
        all_time: all_time_stats,
        free_play_week: free_play_week_stats,
        free_play_month: free_play_month_stats,
        training_week: training_week_stats,
        training_month: training_month_stats,
        inactivity: inactivity_stats
      }
    end

    def by_group
      levels = Level.all.order(:name)
      levels.each_with_object({}) do |level, result|
        users_in_level = User.players.joins(:user_levels).where(user_levels: { level_id: level.id })
        
        result[level.id] = {
          level: level,
          level_name: level.display_name,
          all_time: {
            players: top_player_by_sessions(users_in_level)
          },
          free_play_week: {
            players: top_player_by_sessions_in_period(users_in_level, Session.free_plays.in_current_week(current_week_start))
          },
          free_play_month: {
            players: top_player_by_sessions_in_period(users_in_level, Session.free_plays.in_current_month(current_month_start))
          },
          training_week: {
            players: top_player_by_sessions_in_period(users_in_level, Session.trainings.in_current_week(current_week_start))
          },
          training_month: {
            players: top_player_by_sessions_in_period(users_in_level, Session.trainings.in_current_month(current_month_start))
          },
          inactivity: {
            players: most_inactive_player(users_in_level)
          }
        }
      end
    end

    private

    attr_reader :timezone

    def all_time_stats
      {
        male: top_player_by_sessions_by_gender("male"),
        female: top_player_by_sessions_by_gender("female")
      }
    end

    def free_play_week_stats
      week_start = current_week_start
      sessions = Session.free_plays.in_current_week(week_start)
      {
        male: top_player_by_sessions_in_period_by_gender(sessions, "male"),
        female: top_player_by_sessions_in_period_by_gender(sessions, "female")
      }
    end

    def free_play_month_stats
      month_start = current_month_start
      sessions = Session.free_plays.in_current_month(month_start)
      {
        male: top_player_by_sessions_in_period_by_gender(sessions, "male"),
        female: top_player_by_sessions_in_period_by_gender(sessions, "female")
      }
    end

    def training_week_stats
      week_start = current_week_start
      sessions = Session.trainings.in_current_week(week_start)
      {
        male: top_player_by_sessions_in_period(User.players.male, sessions),
        female: top_player_by_sessions_in_period(User.players.female, sessions)
      }
    end

    def training_month_stats
      month_start = current_month_start
      sessions = Session.trainings.in_current_month(month_start)
      {
        male: top_player_by_sessions_in_period(User.players.male, sessions),
        female: top_player_by_sessions_in_period(User.players.female, sessions)
      }
    end

    def inactivity_stats
      {
        male: most_inactive_player_with_sessions(User.players.male),
        female: most_inactive_player_with_sessions(User.players.female)
      }
    end

    def top_player_by_sessions(users_scope)
      # Get user IDs directly to avoid issues with joins in the scope
      user_ids = users_scope.distinct.pluck(:id)
      return [] if user_ids.empty?

      results = Registration
        .valid
        .joins(:user, :session)
        .where(users: { id: user_ids })
        .group("users.id", "users.first_name", "users.last_name")
        .order("COUNT(registrations.id) DESC")
        .limit(3)
        .pluck("users.id", "users.first_name", "users.last_name", "COUNT(registrations.id)")

      return [] if results.blank?

      results.map do |user_id, first_name, last_name, count|
        {
          user: User.find(user_id),
          count: count,
          name: "#{first_name} #{last_name}".strip
        }
      end
    end

    def top_player_by_sessions_in_period(users_scope, sessions_scope)
      # Get user IDs directly to avoid issues with joins in the scope
      user_ids = users_scope.distinct.pluck(:id)
      return [] if user_ids.empty?

      session_ids = sessions_scope.pluck(:id)
      return [] if session_ids.empty?

      results = Registration
        .valid
        .joins(:user)
        .where(users: { id: user_ids })
        .where(session_id: session_ids)
        .group("users.id", "users.first_name", "users.last_name")
        .order("COUNT(registrations.id) DESC")
        .limit(3)
        .pluck("users.id", "users.first_name", "users.last_name", "COUNT(registrations.id)")

      return [] if results.blank?

      results.map do |user_id, first_name, last_name, count|
        {
          user: User.find(user_id),
          count: count,
          name: "#{first_name} #{last_name}".strip
        }
      end
    end

    def most_inactive_player(users_scope)
      # Get user IDs directly to avoid issues with joins in the scope
      user_ids = users_scope.distinct.pluck(:id)
      return [] if user_ids.empty?

      # Find the last session date for each user who has played
      users_with_sessions = Registration
        .valid
        .joins(:user, :session)
        .where(users: { id: user_ids })
        .group("users.id")
        .maximum("sessions.start_at")

      # Find users who never played
      users_without_sessions = User.where(id: user_ids).where.not(id: users_with_sessions.keys).to_a

      # Build results array
      results = []

      # Add users who never played first (most inactive)
      users_without_sessions.each do |user|
        results << {
          user: user,
          last_session_at: nil,
          days_since: nil,
          name: user.full_name
        }
      end

      # Add users with sessions, sorted by oldest last session first
      if users_with_sessions.any?
        sorted_users = users_with_sessions.sort_by { |_uid, date| date || Time.at(0) }
        sorted_users.each do |user_id, last_session_at|
          user = User.find(user_id)
          days_since = last_session_at ? ((timezone.now - last_session_at.in_time_zone(timezone)) / 1.day).round : nil
          results << {
            user: user,
            last_session_at: last_session_at,
            days_since: days_since,
            name: user.full_name
          }
        end
      end

      # Return top 3 most inactive
      results.first(3)
    end

    def most_inactive_player_with_sessions(users_scope)
      # Get user IDs directly to avoid issues with joins in the scope
      user_ids = users_scope.distinct.pluck(:id)
      return [] if user_ids.empty?

      # Only include users who have at least one session
      users_with_sessions = Registration
        .valid
        .joins(:user, :session)
        .where(users: { id: user_ids })
        .group("users.id")
        .maximum("sessions.start_at")

      return [] if users_with_sessions.blank?

      # Sort by oldest last session first (most inactive)
      sorted_users = users_with_sessions.sort_by { |_uid, date| date || Time.at(0) }
      
      results = sorted_users.map do |user_id, last_session_at|
        user = User.find(user_id)
        days_since = last_session_at ? ((timezone.now - last_session_at.in_time_zone(timezone)) / 1.day).round : nil
        {
          user: user,
          last_session_at: last_session_at,
          days_since: days_since,
          name: user.full_name
        }
      end

      # Return top 3 most inactive
      results.first(3)
    end

    def top_player_by_sessions_by_gender(gender)
      # Get user IDs for the specific gender by joining through user_levels
      user_ids = User.players
        .joins(:user_levels)
        .joins("INNER JOIN levels ON levels.id = user_levels.level_id")
        .where(levels: { gender: gender })
        .distinct
        .pluck(:id)

      return [] if user_ids.empty?

      results = Registration
        .valid
        .joins(:user, :session)
        .where(users: { id: user_ids })
        .group("users.id", "users.first_name", "users.last_name")
        .order("COUNT(registrations.id) DESC")
        .limit(3)
        .pluck("users.id", "users.first_name", "users.last_name", "COUNT(registrations.id)")

      return [] if results.blank?

      results.map do |user_id, first_name, last_name, count|
        {
          user: User.find(user_id),
          count: count,
          name: "#{first_name} #{last_name}".strip
        }
      end
    end

    def top_player_by_sessions_in_period_by_gender(sessions_scope, gender)
      # Get user IDs for the specific gender by joining through user_levels
      user_ids = User.players
        .joins(:user_levels)
        .joins("INNER JOIN levels ON levels.id = user_levels.level_id")
        .where(levels: { gender: gender })
        .distinct
        .pluck(:id)

      return [] if user_ids.empty?

      session_ids = sessions_scope.pluck(:id)
      return [] if session_ids.empty?

      results = Registration
        .valid
        .joins(:user)
        .where(users: { id: user_ids })
        .where(session_id: session_ids)
        .group("users.id", "users.first_name", "users.last_name")
        .order("COUNT(registrations.id) DESC")
        .limit(3)
        .pluck("users.id", "users.first_name", "users.last_name", "COUNT(registrations.id)")

      return [] if results.blank?

      results.map do |user_id, first_name, last_name, count|
        {
          user: User.find(user_id),
          count: count,
          name: "#{first_name} #{last_name}".strip
        }
      end
    end

    def current_week_start
      timezone.now.beginning_of_week(:monday)
    end

    def current_month_start
      timezone.now.beginning_of_month
    end
  end
end

