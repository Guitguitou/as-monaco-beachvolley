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
      label = NotificationLabel.new(@session)
      registered_users = @session.registrations.confirmed.includes(:user).map(&:user)

      ActiveRecord::Base.transaction do
        refund_and_destroy
      end

      notify(registered_users, label.name, label.date)

      { session_name: label.name, session_date: label.date, notified_users: registered_users }
    end

    private

    # Rembourse les inscrits (et le coach d'un coaching privé, qui l'avait payé),
    # garde l'historique des transactions en les détachant, puis supprime.
    def refund_and_destroy
      @session.registrations.includes(:user).find_each do |registration|
        refund(registration.user, registration.required_credits_for(registration.user))
        registration.destroy!
      end
      refund(@session.user, @session.price) if @session.coaching_prive?
      CreditTransaction.where(session_id: @session.id).update_all(session_id: nil)
      @session.destroy!
    end

    def refund(user, amount)
      TransactionService.new(user, @session, amount).refund_transaction if amount.positive?
    end

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
