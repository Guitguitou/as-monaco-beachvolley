module Sessions
  # Applique l'invariant de priorité sur un entraînement :
  # la liste principale (confirmed) = les `max_players` inscriptions actives
  # triées par [priorité hebdomadaire, priorité de groupe, ancienneté].
  # Les joueurs secondaires sont déplacés en liste d'attente si un joueur plus
  # prioritaire prend leur place, et remboursés ; les places libres sont comblées
  # par promotion prioritaire.
  class PriorityBalancerService
    def self.call(session:)
      new(session: session).call
    end

    def initialize(session:)
      @session = session
    end

    def call
      return unless session.entrainement? && session.max_players.present?

      registrations = load_registrations
      weekly.prime(registrations)
      desired_ids = desired_confirmed_ids(registrations)

      # Démotion d'abord : libère les places (et les crédits) avant de promouvoir.
      registrations
        .select { |r| r.confirmed? && !desired_ids.include?(r.id) }
        .each { |registration| demote(registration) }

      # Promotion des joueurs désirés encore en liste d'attente.
      registrations
        .select { |r| r.waitlisted? && desired_ids.include?(r.id) }
        .sort_by { |r| sort_key(r) }
        .each { |registration| promote(registration) }

      # Comble les places restées libres (désinscription simple, promotions échouées).
      Sessions::WaitlistPromotionService.call(session: session, weekly_priority: weekly)
    end

    private

    attr_reader :session

    # Critère A (déjà un entraînement cette semaine ?), puis critère B (groupe),
    # puis ancienneté. `id` départage les created_at égaux, sinon le tri n'est pas
    # déterministe.
    def sort_key(registration)
      [ weekly.rank_for(registration), registration.priority_rank,
        registration.created_at, registration.id ]
    end

    # Snapshot : les pairs vivent sur d'AUTRES sessions, exclues de la requête,
    # donc rien de ce que fait ce service ne peut le périmer pendant l'appel.
    def weekly
      @weekly ||= Registrations::WeeklyPriorityResolver.new(session: session)
    end

    # Précharge users/levels et session_levels pour éviter les N+1 dans priority_rank.
    def load_registrations
      session.association(:session_levels).reset
      session.session_levels.load
      session.registrations.where(status: [ :confirmed, :waitlisted ]).includes(user: :levels).to_a
    end

    # Les max_players inscriptions les plus prioritaires et solvables.
    # Un confirmed a déjà payé (solvable) ; un waitlisted doit avoir assez de crédits.
    def desired_confirmed_ids(registrations)
      registrations.sort_by { |r| sort_key(r) }
                   .select { |registration| registration.confirmed? || list_move.affordable?(registration) }
                   .first(session.max_players)
                   .map(&:id)
    end

    def demote(registration)
      list_move.waitlist(registration)
      notifier.displaced(registration.user)
    rescue StandardError => e
      Rails.logger.error "PriorityBalancer demote failed: #{e.message}"
    end

    def promote(registration)
      list_move.confirm(registration)
      notifier.promoted(registration.user, cause: "Une place s'est libérée pour la session")
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "PriorityBalancer promote failed: #{e.message}"
    end

    def list_move
      @list_move ||= ListMove.new(session)
    end

    def notifier
      @notifier ||= WaitlistNotifier.new(session)
    end
  end
end
