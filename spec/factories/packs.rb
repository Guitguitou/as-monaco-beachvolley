FactoryBot.define do
  factory :pack do
    name { "Pack Test" }
    description { "Description du pack test" }
    pack_type { "credits" }
    amount_cents { 1000 }
    credits { 1000 }
    active { true }
    position { 1 }

    trait :credits do
      pack_type { "credits" }
      credits { 1000 }
    end

    trait :stage do
      pack_type { "stage" }
      credits { nil }
      association :stage
    end

    trait :licence do
      pack_type { "licence" }
      credits { nil }
    end
  end
end
