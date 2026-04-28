module Sessions
  class WaitlistPromotionService
    def self.call(session:)
      new(session: session).call
    end

    def initialize(session:)
      @session = session
    end

    def call
      return unless session.max_players.present?
      return if session.registrations.confirmed.count >= session.max_players

      session.registrations.waitlisted.order(:created_at).each do |registration|
        return registration if promote_registration(registration)
      end

      nil
    end

    private

    attr_reader :session

    def promote_registration(registration)
      amount = session.coaching_prive? ? 0 : session.price.to_i

      if amount.positive? && registration.user.balance.amount < amount
        notify_insufficient_credits(registration.user)
        return false
      end

      promote_with_transaction(registration, amount)
    end

    def promote_with_transaction(registration, amount)
      ActiveRecord::Base.transaction do
        registration.update!(status: :confirmed)
        TransactionService.new(registration.user, session, amount).create_transaction if amount.positive?
      end

      notify_promoted(registration.user)
      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    def notify_insufficient_credits(user)
      SendPushNotificationJob.perform_later(
        user.id,
        title: "Pas assez de crédits",
        body: "Tu n'as pas assez de crédits pour passer en liste principale.",
        url: Rails.application.routes.url_helpers.session_path(session)
      )
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
        body: "Quelqu'un s'est désinscrit de la session #{session_name} du #{session_date} à #{session_time}, tu viens de passer en liste principale",
        url: Rails.application.routes.url_helpers.session_path(session)
      )
      SessionMailer.promoted_to_main_list(user, session).deliver_later
    rescue StandardError => e
      Rails.logger.error "Failed to enqueue notification job: #{e.message}"
    end
  end
end
