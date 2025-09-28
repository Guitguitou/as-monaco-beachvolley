FactoryBot.define do
  factory :stage do
    title { "MyString" }
    description { "MyText" }
    starts_on { "2025-09-28" }
    ends_on { "2025-09-28" }
    main_coach_id { 1 }
    assistant_coach_id { 1 }
  end
end
