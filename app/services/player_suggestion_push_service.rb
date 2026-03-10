# frozen_string_literal: true

require "digest"

class PlayerSuggestionPushService
  THROTTLE_WINDOW = 12.hours
  MAX_NOTIFICATIONS_PER_WINDOW = 3
  DEDUP_WINDOW = 24.hours

  class << self
    def notify_user(user:, event_type:, fingerprint:, title:, body:, url:)
      return false unless user.player_suggestions_push_enabled?
      return false if throttled?(user)
      return false if duplicate?(user, fingerprint)

      SendPushNotificationJob.perform_later(
        user.id,
        title: title,
        body: body,
        url: url
      )

      PlayerSuggestionNotification.create!(
        user: user,
        event_type: event_type,
        fingerprint: digest(fingerprint)
      )

      true
    end

    private

    def throttled?(user)
      PlayerSuggestionNotification
        .where(user: user)
        .where("created_at >= ?", THROTTLE_WINDOW.ago)
        .count >= MAX_NOTIFICATIONS_PER_WINDOW
    end

    def duplicate?(user, fingerprint)
      PlayerSuggestionNotification
        .where(user: user, fingerprint: digest(fingerprint))
        .where("created_at >= ?", DEDUP_WINDOW.ago)
        .exists?
    end

    def digest(fingerprint)
      Digest::SHA256.hexdigest(fingerprint.to_s)
    end
  end
end
