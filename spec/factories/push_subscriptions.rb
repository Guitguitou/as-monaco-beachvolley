# frozen_string_literal: true

FactoryBot.define do
  factory :push_subscription do
    association :user
    endpoint { "https://fcm.googleapis.com/fcm/send/#{SecureRandom.hex(32)}" }
    p256dh { Base64.urlsafe_encode64(SecureRandom.random_bytes(65), padding: false) }
    auth { Base64.urlsafe_encode64(SecureRandom.random_bytes(16), padding: false) }
  end
end
