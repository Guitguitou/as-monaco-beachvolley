# frozen_string_literal: true

# Service for sending push notifications to users
class PushNotificationService
  class << self
    # Send a notification to a specific user
    # @param user [User] The user to notify
    # @param title [String] Notification title
    # @param body [String] Notification body
    # @param url [String] Optional URL to open when notification is clicked
    # @param icon [String] Optional icon URL
    def send_to_user(user, title:, body:, url: nil, icon: nil)
      sender = delivery
      user.push_subscriptions.find_each do |subscription|
        sender.call(subscription, title: title, body: body, url: url, icon: icon)
      end
    end

    # Send a notification to multiple users
    # @param users [Array<User>] The users to notify
    # @param title [String] Notification title
    # @param body [String] Notification body
    # @param url [String] Optional URL to open when notification is clicked
    # @param icon [String] Optional icon URL
    def send_to_users(users, title:, body:, url: nil, icon: nil)
      users.find_each do |user|
        send_to_user(user, title: title, body: body, url: url, icon: icon)
      end
    end

    # Send a notification based on an event type
    # This will check all enabled notification rules for the event type
    # @param event_type [String] The event type (e.g., 'session_created')
    # @param context [Hash] Context data for the event (e.g., { session: session, user: user })
    def send_for_event(event_type, context: {})
      NotificationRule.enabled.for_event(event_type).each do |rule|
        next unless rule.matches?(context)

        routing = PushNotifications::EventRouting.new(event_type, context)
        routing.users.find_each do |user|
          user_context = context.merge(user: user)
          send_to_user(user, title: rule.render_title(user_context), body: rule.render_body(user_context), url: routing.url)
        end
      end
    end

    private

    def delivery
      PushNotifications::WebpushDelivery.new(vapid: vapid, default_icon: default_icon, default_url: root_url)
    end

    def routes
      Rails.application.routes.url_helpers
    end

    def default_icon
      # Utilise le logo de l'app pour les notifications
      ActionController::Base.helpers.asset_url("logo.png").presence || "/logo.png"
    rescue StandardError
      "/logo.png"
    end

    def root_url
      host = Rails.application.config.action_mailer.default_url_options[:host] || ENV["HOST"] || "localhost:3000"
      routes.root_url(host: host)
    end

    def vapid
      credentials = Rails.application.credentials.vapid || {}
      {
        subject: ENV["VAPID_SUBJECT"] || credentials[:subject] || root_url,
        public_key: ENV["VAPID_PUBLIC_KEY"] || credentials[:public_key] || "",
        private_key: ENV["VAPID_PRIVATE_KEY"] || credentials[:private_key] || ""
      }
    end
  end
end
