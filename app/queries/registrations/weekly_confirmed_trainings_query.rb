module Registrations
  # Inscriptions confirmées à des entraînements sur une plage de dates, pour un
  # ensemble de joueurs. Ce qui sert au calcul de priorité hebdomadaire, c'est la
  # clé d'ancienneté d'une inscription, pas l'objet ActiveRecord : on ne remonte
  # donc que des tuples, en une seule requête quel que soit le nombre de joueurs.
  class WeeklyConfirmedTrainingsQuery
    def self.call(user_ids:, range:, excluded_session_id: nil)
      new(user_ids: user_ids, range: range, excluded_session_id: excluded_session_id).call
    end

    def initialize(user_ids:, range:, excluded_session_id: nil)
      @user_ids = Array(user_ids).compact.uniq
      @range = range
      @excluded_session_id = excluded_session_id
    end

    # [[user_id, session_id, created_at, id, session_start_at], ...]
    # Trié par (user_id, created_at, id) : la première ligne d'un joueur est sa
    # plus ancienne inscription.
    def call
      return [] if user_ids.empty?

      scope = Registration
        .where(user_id: user_ids, status: Registration.statuses[:confirmed])
        .joins(:session)
        .where(sessions: { session_type: "entrainement", start_at: range })
      scope = scope.where.not(session_id: excluded_session_id) if excluded_session_id

      scope.order(:user_id, :created_at, :id)
           .pluck(:user_id, :session_id, "registrations.created_at", "registrations.id", "sessions.start_at")
    end

    private

    attr_reader :user_ids, :range, :excluded_session_id
  end
end
