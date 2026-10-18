module Sessions
  # Supprime une session saisie par erreur (cf. GLOSSARY.md, « Suppression de
  # séance ») : rembourse et prévient les inscrits, garde l'historique des
  # transactions en le détachant, puis efface la session.
  class DestroySessionService
    def self.call(session:)
      new(session: session).call
    end

    def initialize(session:)
      @session = session
    end

    def call
      label = NotificationLabel.new(@session)

      notified_users = ActiveRecord::Base.transaction do
        users = RegistrationsRefund.new(@session).call
        CreditTransaction.where(session_id: @session.id).update_all(session_id: nil)
        @session.destroy!
        users
      end

      CancellationNotifier.new(session_name: label.name, session_date: label.date).call(notified_users)
    end
  end
end
