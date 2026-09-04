# frozen_string_literal: true

module Stats
  # Statistiques personnelles d'un joueur, pour sa page de profil.
  #
  # Stats::PerformanceDashboard répond à une autre question : il classe *tous*
  # les joueurs de *tous* les niveaux, et instancie un User par ligne de
  # classement. L'appeler pour n'en garder qu'une ligne coûterait la totalité
  # de ces requêtes. Cette classe fait le travail scopé à un seul joueur.
  #
  # Le classement reprend volontairement les mêmes règles que
  # PerformanceDashboard#full_ranking_by_sessions (toutes les inscriptions
  # confirmées, comptes de test exclus, égalité tranchée par ancienneté) pour
  # que le rang affiché ici soit le même que sur /performances.
  class PlayerStats
    EXCLUDED_LAST_NAME = "Test"

    Result = Struct.new(
      :sessions_played,
      :trainings_played,
      :free_plays_played,
      :late_cancellations,
      :last_session_at,
      :level,
      :rank_in_group,
      :group_size,
      keyword_init: true
    ) do
      def any_session?
        sessions_played.to_i.positive?
      end

      def ranked?
        rank_in_group.present? && group_size.to_i > 1
      end
    end

    def initialize(user:)
      @user = user
    end

    def call
      Result.new(
        sessions_played: played_counts.values.sum,
        trainings_played: played_counts["entrainement"].to_i,
        free_plays_played: played_counts["jeu_libre"].to_i,
        late_cancellations: LateCancellation.where(user_id: user.id).count,
        last_session_at: last_session_at,
        level: level,
        rank_in_group: ranking[:rank],
        group_size: ranking[:size]
      )
    end

    private

    attr_reader :user

    # Une seule requête : nombre de sessions jouées par type.
    def played_counts
      @played_counts ||= Registration
        .valid
        .joins(:session)
        .where(user_id: user.id)
        .where(sessions: { start_at: ...Time.current })
        .group("sessions.session_type")
        .count
    end

    def last_session_at
      @last_session_at ||= Registration
        .valid
        .joins(:session)
        .where(user_id: user.id)
        .where(sessions: { start_at: ...Time.current })
        .maximum("sessions.start_at")
    end

    def level
      @level ||= user.levels.first
    end

    # Rang du joueur parmi les membres de son groupe principal.
    # Deux requêtes : les ids du groupe, puis les comptes groupés.
    def ranking
      @ranking ||= compute_ranking
    end

    NO_RANKING = { rank: nil, size: 0 }.freeze

    def compute_ranking
      return NO_RANKING if level.blank?

      peer_ids = UserLevel.where(level_id: level.id).pluck(:user_id)
      return NO_RANKING if peer_ids.empty?

      ordered_ids = Registration
        .valid
        .joins(:user, :session)
        .where(users: { id: peer_ids })
        .where.not(users: { last_name: EXCLUDED_LAST_NAME })
        .group("users.id")
        .order(Arel.sql("COUNT(registrations.id) DESC, MIN(registrations.created_at) ASC"))
        .count
        .keys

      position = ordered_ids.index(user.id)

      { rank: position ? position + 1 : nil, size: ordered_ids.size }
    end
  end
end
