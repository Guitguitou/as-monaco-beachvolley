FactoryBot.define do
  factory :user do
    first_name { "John" }
    last_name { "Doe" }
    sequence(:email) { |n| "john.doe#{n}@example.com" }
    password { "password123" }
    coach { false }
    responsable { false }
    admin { false }

    trait :coach do
      coach { true }
    end

    trait :responsable do
      responsable { true }
    end

    trait :admin do
      admin { true }
    end
  end
end
