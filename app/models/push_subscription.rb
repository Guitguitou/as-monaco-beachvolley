# frozen_string_literal: true

# Model for storing push notification subscriptions
# Each subscription is tied to a user and contains the necessary keys
# for sending push notifications via the Web Push API
class PushSubscription < ApplicationRecord
  belongs_to :user

  validates :endpoint, presence: true, uniqueness: { scope: :user_id }
  validates :p256dh, presence: true
  validates :auth, presence: true
end
