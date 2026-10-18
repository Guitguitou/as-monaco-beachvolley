module Sessions
  # Annule une session (cf. GLOSSARY.md, « Séance annulée ») : elle reste
  # visible avec son motif, les inscrits sont remboursés et prévenus, et ses
  # désinscriptions tardives deviennent excusées.
  class CancelSessionService
    def self.call(session:, reason:)
      new(session: session, reason: reason).call
    end

    def initialize(session:, reason:)
      raise ArgumentError, "Motif d'annulation inconnu : #{reason}" unless Session.cancellation_reasons.key?(reason.to_s)

      @session = session
      @reason = reason.to_s
    end

    def call
      label = NotificationLabel.new(@session)

      notified_users = ActiveRecord::Base.transaction do
        users = RegistrationsRefund.new(@session).call
        LateCancellation.where(session_id: @session.id).update_all(excused: true)
        @session.update!(cancelled_at: Time.current, cancellation_reason: @reason)
        users
      end

      CancellationNotifier.new(session_name: label.name, session_date: label.date).call(notified_users)

      { session_name: label.name, session_date: label.date, notified_users: notified_users }
    end
  end
end
