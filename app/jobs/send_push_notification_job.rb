# frozen_string_literal: true

# Background job for sending push notifications
# This allows notifications to be sent asynchronously without blocking the main request
class SendPushNotificationJob < ApplicationJob
  queue_as :default

  # Send a notification to a user
  # @param user_id [Integer] The ID of the user to notify
  # @param title [String] Notification title
  # @param body [String] Notification body
  # @param url [String] Optional URL to open when notification is clicked
  # @param icon [String] Optional icon URL
  def perform(user_id, title:, body:, url: nil, icon: nil)
    user = User.find(user_id)
    PushNotificationService.send_to_user(user, title: title, body: body, url: url, icon: icon)
  end
end
