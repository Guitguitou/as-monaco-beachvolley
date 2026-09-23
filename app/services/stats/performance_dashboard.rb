# frozen_string_literal: true

module Stats
  class PerformanceDashboard
    GENDERS = %w[male female].freeze

    def initialize(timezone: "Europe/Paris")
      @timezone = ActiveSupport::TimeZone[timezone]
    end

    def call
      {
        all_time: by_gender { |user_ids| SessionCountRanking.new(user_ids: user_ids).top },
        free_play_week: top_by_gender(Session.free_plays.in_current_week(current_week_start)),
        free_play_month: top_by_gender(Session.free_plays.in_current_month(current_month_start)),
        training_week: top_by_gender(Session.trainings.in_current_week(current_week_start)),
        training_month: top_by_gender(Session.trainings.in_current_month(current_month_start)),
        inactivity: by_gender { |user_ids| InactivityRanking.new(user_ids: user_ids, timezone: timezone).top }
      }
    end

    def by_group
      Level.all.order(:name).each_with_object({}) do |level, result|
        # Tous les utilisateurs du niveau, pas seulement les joueurs : coachs et
        # responsables peuvent aussi avoir un niveau et des inscriptions.
        user_ids = UserLevel.where(level_id: level.id).joins(:user).pluck(:user_id)
        result[level.id] = { level: level, level_name: level.display_name, **group_stats(user_ids) }
      end
    end

    private

    attr_reader :timezone

    def group_stats(user_ids)
      {
        all_time: {
          players: SessionCountRanking.new(user_ids: user_ids).top,
          full_ranking: SessionCountRanking.new(user_ids: user_ids).full
        },
        free_play_week: { players: top(user_ids, Session.free_plays.in_current_week(current_week_start)) },
        free_play_month: { players: top(user_ids, Session.free_plays.in_current_month(current_month_start)) },
        free_play_total: { full_ranking: SessionCountRanking.new(user_ids: user_ids, sessions: Session.free_plays).full },
        training_week: { players: top(user_ids, Session.trainings.in_current_week(current_week_start)) },
        training_month: { players: top(user_ids, Session.trainings.in_current_month(current_month_start)) },
        training_total: { full_ranking: SessionCountRanking.new(user_ids: user_ids, sessions: Session.trainings).full },
        inactivity: { players: InactivityRanking.new(user_ids: user_ids, timezone: timezone, include_never_played: true).top }
      }
    end

    def top_by_gender(sessions)
      by_gender { |user_ids| top(user_ids, sessions) }
    end

    def top(user_ids, sessions)
      SessionCountRanking.new(user_ids: user_ids, sessions: sessions).top
    end

    def by_gender
      GENDERS.to_h { |gender| [ gender.to_sym, yield(user_ids_for(gender)) ] }
    end

    # Tous les utilisateurs ayant un niveau de ce genre, pas seulement les
    # joueurs : coachs, responsables et admins peuvent aussi s'inscrire.
    def user_ids_for(gender)
      User.joins(user_levels: :level).where(levels: { gender: gender }).distinct.pluck(:id)
    end

    def current_week_start
      timezone.now.beginning_of_week(:monday)
    end

    def current_month_start
      timezone.now.beginning_of_month
    end
  end
end
