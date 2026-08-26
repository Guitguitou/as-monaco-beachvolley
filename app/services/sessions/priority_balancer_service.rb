module Sessions
  # Applique l'invariant de priorité sur un entraînement :
  # la liste principale (confirmed) = les `max_players` inscriptions actives
  # triées par [priority_rank, created_at]. Les joueurs secondaires sont
  # déplacés en liste d'attente si un joueur plus prioritaire prend leur place,
  # et remboursés ; les places libres sont comblées par promotion prioritaire.
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
      desired_ids = desired_confirmed_ids(registrations)

      # Démotion d'abord : libère les places (et les crédits) avant de promouvoir.
      registrations
        .select { |r| r.confirmed? && !desired_ids.include?(r.id) }
        .each { |registration| demote(registration) }

      # Promotion des joueurs désirés encore en liste d'attente.
      registrations
        .select { |r| r.waitlisted? && desired_ids.include?(r.id) }
        .sort_by { |r| [ r.priority_rank, r.created_at ] }
        .each { |registration| promote(registration) }

      # Comble les places restées libres (désinscription simple, promotions échouées).
      Sessions::WaitlistPromotionService.call(session: session)
    end

    private

    attr_reader :session

    def price
      @price ||= session.coaching_prive? ? 0 : session.price.to_i
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
      sorted = registrations.sort_by { |r| [ r.priority_rank, r.created_at ] }
      desired = []
      sorted.each do |registration|
        break if desired.size >= session.max_players
        next unless registration.confirmed? || affordable?(registration)
        desired << registration.id
      end
      desired
    end

    def affordable?(registration)
      price <= 0 || registration.user.balance.amount >= price
    end

    def demote(registration)
      ActiveRecord::Base.transaction do
        registration.update!(status: :waitlisted)
        TransactionService.new(registration.user, session, price).refund_transaction if price.positive?
      end
      notify_displaced(registration.user)
    rescue StandardError => e
      Rails.logger.error "PriorityBalancer demote failed: #{e.message}"
    end

    def promote(registration)
      ActiveRecord::Base.transaction do
        registration.update!(status: :confirmed)
        TransactionService.new(registration.user, session, price).create_transaction if price.positive?
      end
      notify_promoted(registration.user)
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "PriorityBalancer promote failed: #{e.message}"
    end

    def notify_displaced(user)
      session_name = session.title || session.session_type.humanize
      session_date = session.start_at.strftime("%d/%m/%Y")
      session_time = session.start_at.strftime("%Hh%M")

      SendPushNotificationJob.perform_later(
        user.id,
        title: "Tu repasses en liste d'attente",
        body: "Un joueur prioritaire s'est inscrit à #{session_name} du #{session_date} à #{session_time}, tu repasses en liste d'attente (crédits recrédités).",
        url: Rails.application.routes.url_helpers.session_path(session)
      )
      SessionMailer.displaced_to_waitlist(user, session).deliver_later
    rescue StandardError => e
      Rails.logger.error "Failed to enqueue notification job: #{e.message}"
    end

    def notify_promoted(user)
      session_name = session.title || session.session_type.humanize
      session_date = session.start_at.strftime("%d/%m/%Y")
      session_time = session.start_at.strftime("%Hh%M")

      SendPushNotificationJob.perform_later(
        user.id,
        title: "Tu passes en liste principale !",
        body: "Une place s'est libérée pour la session #{session_name} du #{session_date} à #{session_time}, tu viens de passer en liste principale",
        url: Rails.application.routes.url_helpers.session_path(session)
      )
      SessionMailer.promoted_to_main_list(user, session).deliver_later
    rescue StandardError => e
      Rails.logger.error "Failed to enqueue notification job: #{e.message}"
    end
  end
end
