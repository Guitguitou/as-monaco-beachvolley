# frozen_string_literal: true

module Sessions
  # Prévient un joueur que sa place a bougé entre liste principale et liste
  # d'attente. Une notification qui échoue ne doit jamais annuler le mouvement.
  class WaitlistNotifier
    def initialize(session)
      @session = session
    end

    # `cause` ouvre le message : ce qui a libéré la place.
    def promoted(user, cause:)
      push(user, title: "Tu passes en liste principale !",
                 body: "#{cause} #{label}, tu viens de passer en liste principale") do
        SessionMailer.promoted_to_main_list(user, @session).deliver_later
      end
    end

    def displaced(user)
      push(user, title: "Tu repasses en liste d'attente",
                 body: "Un joueur prioritaire s'est inscrit à #{label}, tu repasses en liste d'attente (crédits recrédités).") do
        SessionMailer.displaced_to_waitlist(user, @session).deliver_later
      end
    end

    def insufficient_credits(user)
      push(user, title: "Pas assez de crédits", body: "Tu n'as pas assez de crédits pour passer en liste principale.")
    end

    private

    def push(user, title:, body:)
      SendPushNotificationJob.perform_later(user.id, title: title, body: body, url: Rails.application.routes.url_helpers.session_path(@session))
      yield if block_given?
    rescue StandardError => e
      Rails.logger.error "Failed to enqueue notification job: #{e.message}"
    end

    def label
      NotificationLabel.new(@session)
    end
  end
end
