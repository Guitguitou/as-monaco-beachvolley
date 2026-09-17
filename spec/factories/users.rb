FactoryBot.define do
  factory :user do
    first_name { "John" }
    last_name { "Doe" }
    sequence(:email) { |n| "john.doe#{n}@example.com" }
    password { "password123" }
    # Licence active par défaut : sans elle, toute requête authentifiée est
    # redirigée vers /packs. Les specs du parcours non activé passent
    # explicitement `activated_at: nil`.
    activated_at { Time.current }
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

    trait :financial_manager do
      financial_manager { true }
    end
  end
end
