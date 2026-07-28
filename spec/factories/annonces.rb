FactoryBot.define do
  factory :annonce do
    association :user
    title { "Jeu libre détente" }
    description { "On monte une session tranquille" }
    status { :open }
    min_players { 4 }

    trait :confirmed do
      status { :confirmed }
    end

    trait :cancelled do
      status { :cancelled }
    end

    # Annonce avec un créneau déjà construit (demain 19h → 21h par défaut).
    trait :with_slot do
      after(:build) do |annonce|
        annonce.slots << build(:annonce_slot, annonce: annonce)
      end
    end
  end

  factory :annonce_slot do
    association :annonce
    start_at { (Time.current + 1.day).change(hour: 19, min: 0) }
    end_at   { (Time.current + 1.day).change(hour: 21, min: 0) }
  end

  factory :annonce_availability do
    association :annonce_slot
    association :user
  end
end
