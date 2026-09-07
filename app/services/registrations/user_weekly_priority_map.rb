module Registrations
  # Rang A (cf. WeeklyPriorityRule) d'UN joueur sur un lot de sessions — la
  # grille, « Mes sessions », la fiche session. Une seule requête couvre toute la
  # plage affichée : { session_id => 0|1 }.
  #
  # Pour une session où le joueur n'est pas confirmé, on retourne le rang qu'il
  # AURAIT s'il s'inscrivait maintenant : c'est l'information utile avant le clic.
  class UserWeeklyPriorityMap
    def self.call(user:, sessions:)
      new(user: user).ranks_for(sessions: sessions)
    end

    def initialize(user:)
      @user = user
    end

    def ranks_for(sessions:)
      trainings = Array(sessions).select { |s| s.entrainement? && s.start_at.present? }
      return {} if user.blank? || trainings.empty?

      rows = load_rows(trainings)
      trainings.uniq(&:id).index_by(&:id).transform_values { |session| rank_for(session, rows) }
    end

    private

    attr_reader :user

    def load_rows(trainings)
      starts = trainings.map { |s| s.start_at.in_time_zone }
      range = starts.min.beginning_of_week(:monday)..starts.max.end_of_week(:monday)

      WeeklyConfirmedTrainingsQuery.call(user_ids: [ user.id ], range: range)
        .map { |_user_id, session_id, created_at, id, start_at| { session_id: session_id, key: [ created_at, id ], start_at: start_at } }
    end

    def rank_for(session, rows)
      return WeeklyPriorityRule::PRIORITY if WeeklyPriorityRule.neutral_week?(session.start_at)

      week = WeeklyPriorityRule.week_range(session.start_at)
      own = rows.find { |row| row[:session_id] == session.id }
      own_key = WeeklyPriorityRule.key(own&.fetch(:key)&.first, own&.fetch(:key)&.last)

      peers = rows.select { |row| row[:session_id] != session.id && week.cover?(row[:start_at]) }
      WeeklyPriorityRule.rank(earliest_peer_key: peers.map { |row| row[:key] }.min, own_key: own_key)
    end
  end
end
