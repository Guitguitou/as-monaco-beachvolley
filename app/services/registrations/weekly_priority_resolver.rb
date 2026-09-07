module Registrations
  # Rang A (cf. WeeklyPriorityRule) des inscriptions d'UNE session, pour N joueurs.
  # `prime` charge en une seule requête la plus ancienne inscription de chaque
  # joueur sur la semaine ; `rank_for` lit ensuite en mémoire. Utilisé par les
  # services de tri, qui trient des dizaines d'inscriptions d'un coup.
  class WeeklyPriorityResolver
    def initialize(session:)
      @session = session
      @peers = {}
      @primed_user_ids = Set.new
    end

    def neutral?
      return @neutral if defined?(@neutral)

      @neutral = !session.entrainement? ||
                 session.start_at.blank? ||
                 WeeklyPriorityRule.neutral_week?(session.start_at)
    end

    # Charge les pairs de tous ces joueurs en une requête. Idempotent.
    def prime(registrations)
      return self if neutral?

      missing = Array(registrations).map(&:user_id).compact.uniq - primed_user_ids.to_a
      load_peers(missing) if missing.any?
      self
    end

    def rank_for(registration)
      rank_for_user(registration.user_id,
                    WeeklyPriorityRule.key(registration.created_at, registration.id))
    end

    # Rang qu'aurait une inscription créée maintenant — ce qu'on affiche au joueur
    # avant qu'il ne clique.
    def rank_for_new(user_id)
      rank_for_user(user_id, WeeklyPriorityRule.key(nil, nil))
    end

    private

    attr_reader :session, :peers, :primed_user_ids

    def rank_for_user(user_id, own_key)
      return WeeklyPriorityRule::PRIORITY if neutral? || user_id.blank?

      load_peers([ user_id ]) unless primed_user_ids.include?(user_id)
      WeeklyPriorityRule.rank(earliest_peer_key: peers[user_id], own_key: own_key)
    end

    def load_peers(user_ids)
      rows = WeeklyConfirmedTrainingsQuery.call(
        user_ids: user_ids,
        range: WeeklyPriorityRule.week_range(session.start_at),
        excluded_session_id: session.id
      )
      # Trié par (user_id, created_at, id) : la première ligne d'un joueur suffit.
      rows.each { |user_id, _session_id, created_at, id, _start_at| peers[user_id] ||= [ created_at, id ] }
      primed_user_ids.merge(user_ids)
    end
  end
end
