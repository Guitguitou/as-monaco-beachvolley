# frozen_string_literal: true

FactoryBot.define do
  factory :stage do
    title { "Stage Test" }
    description { "Description du stage test" }
    starts_on { Date.current + 1.week }
    ends_on { Date.current + 2.weeks }
    main_coach { nil }
    assistant_coach { nil }
  end
end
