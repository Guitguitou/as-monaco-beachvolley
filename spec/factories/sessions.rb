# frozen_string_literal: true

FactoryBot.define do
  factory :session do
    title { "Session de test" }
    description { "Description de test" }
    start_at { 1.hour.from_now }
    end_at { 2.hours.from_now }
    session_type { "entrainement" }
    terrain { "Terrain 1" }
    user
    max_players { 12 }

    trait :jeu_libre do
      session_type { "jeu_libre" }
      title { "Jeu libre" }
    end

    trait :tournoi do
      session_type { "tournoi" }
      title { "Tournoi" }
    end

    trait :coaching_prive do
      session_type { "coaching_prive" }
      title { "Coaching privé" }
    end

    trait :terrain_2 do
      terrain { "Terrain 2" }
    end

    trait :terrain_3 do
      terrain { "Terrain 3" }
    end
  end
end
