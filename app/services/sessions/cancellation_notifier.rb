module Sessions
  # Prévient (push + email) les joueurs d'une session qui n'aura pas lieu.
  class CancellationNotifier
    def initialize(session_name:, session_date:)
      @session_name = session_name
      @session_date = session_date
    end

    def call(users)
      users.each do |user|
        SendPushNotificationJob.perform_later(
          user.id,
          title: "Session annulée",
          body: "La session #{@session_name} du #{@session_date} est annulée",
          url: Rails.application.routes.url_helpers.sessions_path
        )
        SessionMailer.session_cancelled(user, session_name: @session_name, session_date: @session_date).deliver_later
      rescue StandardError => e
        Rails.logger.error "Failed to enqueue notification job for user #{user.id}: #{e.message}"
      end
    end
  end
end
