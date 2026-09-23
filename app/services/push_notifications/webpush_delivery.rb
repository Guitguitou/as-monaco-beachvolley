# frozen_string_literal: true

require "webpush"

module PushNotifications
  # Envoie une notification à un abonnement Web Push, et oublie l'abonnement
  # quand le navigateur l'a révoqué.
  class WebpushDelivery
    def initialize(vapid:, default_icon:, default_url:)
      @vapid = vapid
      @default_icon = default_icon
      @default_url = default_url
    end

    def call(subscription, title:, body:, url: nil, icon: nil)
      message = { title: title, body: body, icon: icon || @default_icon, badge: @default_icon, data: { url: url || @default_url } }
      Webpush.payload_send(message: message.to_json, endpoint: subscription.endpoint,
                           p256dh: subscription.p256dh, auth: subscription.auth, vapid: @vapid)
    rescue Webpush::InvalidSubscription, Webpush::ExpiredSubscription => e
      Rails.logger.warn "Removing invalid push subscription: #{e.message}"
      subscription.destroy
    rescue StandardError => e
      Rails.logger.error "Error sending push notification: #{e.message}"
      raise
    end
  end
end
