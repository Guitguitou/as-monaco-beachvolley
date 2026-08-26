module Sessions
  # Annule (supprime) une session en remboursant les participants confirmés
  # puis en notifiant push + email. Extrait de SessionsController#cancel pour
  # être réutilisable (annulation unitaire et suppression de séries).
  class CancelSessionService
    def self.call(session:)
      new(session: session).call
    end

    def initialize(session:)
      @session = session
    end

    # Détruit la session en remboursant/notifiant. Lève en cas d'échec de la
    # transaction destructive (à charge de l'appelant de rescue si besoin).
    def call
      session_name = @session.title || @session.session_type.humanize
      session_date = @session.start_at.strftime("%d/%m/%Y")
      registered_users = @session.registrations.confirmed.includes(:user).map(&:user)

      ActiveRecord::Base.transaction do
        @session.registrations.includes(:user).find_each do |registration|
          amount = registration.required_credits_for(registration.user)
          TransactionService.new(registration.user, @session, amount).refund_transaction if amount.positive?
          registration.destroy!
        end

        if @session.coaching_prive?
          coach_amount = @session.send(:default_price)
          TransactionService.new(@session.user, @session, coach_amount).refund_transaction if coach_amount.positive?
        end

        CreditTransaction.where(session_id: @session.id).update_all(session_id: nil)
        @session.destroy!
      end

      notify(registered_users, session_name, session_date)

      { session_name: session_name, session_date: session_date, notified_users: registered_users }
    end

    private

    def notify(registered_users, session_name, session_date)
      registered_users.each do |user|
        SendPushNotificationJob.perform_later(
          user.id,
          title: "Session annulée",
          body: "La session #{session_name} du #{session_date} est annulée",
          url: Rails.application.routes.url_helpers.sessions_path
        )
        SessionMailer.session_cancelled(user, session_name: session_name, session_date: session_date).deliver_later
      rescue StandardError => e
        Rails.logger.error "Failed to enqueue notification job for user #{user.id}: #{e.message}"
      end
    end
  end
end
