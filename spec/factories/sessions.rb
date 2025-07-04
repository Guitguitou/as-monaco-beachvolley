FactoryBot.define do
  factory :session do
    title { "MyString" }
    description { "MyText" }
    start_at { "2025-07-04 15:28:18" }
    end_at { "2025-07-04 15:28:18" }
    session_type { "MyString" }
    user { nil }
    max_players { 1 }
  end
end
