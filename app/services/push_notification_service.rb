# frozen_string_literal: true

require "webpush"

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
      return if user.push_subscriptions.empty?

      user.push_subscriptions.find_each do |subscription|
        send_to_subscription(subscription, title: title, body: body, url: url, icon: icon)
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
      rules = NotificationRule.enabled.for_event(event_type)

      rules.each do |rule|
        next unless rule.matches?(context)

        # Determine target users based on context
        users = determine_target_users(event_type, context)

        users.find_each do |user|
          title = rule.render_title(context.merge(user: user))
          body = rule.render_body(context.merge(user: user))
          url = determine_notification_url(event_type, context)

          send_to_user(user, title: title, body: body, url: url)
        end
      end
    end

    private

    def send_to_subscription(subscription, title:, body:, url: nil, icon: nil)
      message = {
        title: title,
        body: body,
        icon: icon || default_icon,
        badge: default_icon,
        data: {
          url: url || root_url
        }
      }

      Webpush.payload_send(
        message: JSON.generate(message),
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh,
        auth: subscription.auth,
        vapid: {
          subject: vapid_subject,
          public_key: vapid_public_key,
          private_key: vapid_private_key
        }
      )
    rescue Webpush::InvalidSubscription, Webpush::ExpiredSubscription => e
      # Subscription is invalid, remove it
      Rails.logger.warn "Removing invalid push subscription: #{e.message}"
      subscription.destroy
    rescue StandardError => e
      Rails.logger.error "Error sending push notification: #{e.message}"
      raise
    end

    def determine_target_users(event_type, context)
      case event_type
      when "session_created", "session_cancelled", "registration_opened"
        # Notify all activated users
        User.activated
      when "registration_confirmed", "registration_cancelled"
        # Notify the user who registered
        User.where(id: context[:user]&.id)
      when "credit_low"
        # Notify users with low credits
        User.activated.joins(:balance).where("balances.amount < ?", 10)
      when "stage_created", "stage_registration_opened"
        # Notify all activated users
        User.activated
      else
        User.none
      end
    end

    def determine_notification_url(event_type, context)
      case event_type
      when "session_created", "session_cancelled", "registration_opened"
        context[:session] ? session_path(context[:session]) : sessions_path
      when "registration_confirmed", "registration_cancelled"
        context[:session] ? session_path(context[:session]) : me_sessions_path
      when "credit_low"
        packs_path
      when "stage_created", "stage_registration_opened"
        context[:stage] ? stage_path(context[:stage]) : stages_path
      else
        root_path
      end
    end

    def default_icon
      asset_url("icon.png") || asset_url("icon.svg")
    end

    def root_url
      Rails.application.routes.url_helpers.root_url(host: default_host)
    end

    def root_path
      Rails.application.routes.url_helpers.root_path
    end

    def sessions_path
      Rails.application.routes.url_helpers.sessions_path
    end

    def session_path(session)
      Rails.application.routes.url_helpers.session_path(session)
    end

    def me_sessions_path
      Rails.application.routes.url_helpers.me_sessions_path
    end

    def packs_path
      Rails.application.routes.url_helpers.packs_path
    end

    def stages_path
      Rails.application.routes.url_helpers.stages_path
    end

    def stage_path(stage)
      Rails.application.routes.url_helpers.stage_path(stage)
    end

    def default_host
      Rails.application.config.action_mailer.default_url_options[:host] ||
        ENV["HOST"] ||
        "localhost:3000"
    end

    def asset_url(path)
      ActionController::Base.helpers.asset_url(path)
    rescue StandardError
      nil
    end

    def vapid_public_key
      ENV["VAPID_PUBLIC_KEY"] || Rails.application.credentials.dig(:vapid, :public_key) || ""
    end

    def vapid_private_key
      ENV["VAPID_PRIVATE_KEY"] || Rails.application.credentials.dig(:vapid, :private_key) || ""
    end

    def vapid_subject
      ENV["VAPID_SUBJECT"] || Rails.application.credentials.dig(:vapid, :subject) || root_url
    end
  end
end
