# frozen_string_literal: true

FactoryBot.define do
  factory :notification_rule do
    name { "Test Notification Rule" }
    event_type { "session_created" }
    title_template { "Test Title: {{session_name}}" }
    body_template { "Test Body: {{session_date}}" }
    enabled { true }
    conditions { {} }

    trait :disabled do
      enabled { false }
    end

    trait :with_conditions do
      conditions { { "user_level" => "advanced" } }
    end
  end
end
