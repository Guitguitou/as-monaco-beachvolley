FactoryBot.define do
  factory :session do
    title { "Session de test" }
    description { "Description de test" }
    # Un terrain n'accepte qu'une session à la fois : sans créneau distinct,
    # deux sessions par défaut se chevauchent et la validation les rejette.
    # La séquence est remise à zéro avant chaque exemple (cf. rails_helper),
    # les créneaux restent donc proches de l'heure courante.
    sequence(:start_at) { |n| 1.hour.from_now.change(min: 0) + (n - 1) * 2.hours }
    end_at { start_at + 90.minutes }
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
