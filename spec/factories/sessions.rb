FactoryBot.define do
  factory :session do
    title { "Session de test" }
    description { "Description de test" }
    # Un terrain n'accepte qu'une session à la fois : sans créneau distinct,
    # deux sessions par défaut se chevauchent et la validation les rejette.
    # La séquence est remise à zéro avant chaque exemple (cf. rails_helper).
    # Créneaux dès demain matin : une session du jour même serait fermée aux
    # inscriptions passé 17h (REGISTRATION_DEADLINE_HOUR), selon l'heure du run.
    sequence(:start_at) { |n| 1.day.from_now.change(hour: 9) + (n - 1) * 2.hours }
    end_at { start_at + 90.minutes }
    session_type { "entrainement" }
    user
    max_players { 12 }

    # `terrain` : nom, Terrain ou nil (cf. FactoryHelpers.resolve_terrain).
    transient do
      terrain { "Terrain 1" }
    end

    after(:build) do |session, evaluator|
      session.terrain = FactoryHelpers.resolve_terrain(evaluator.terrain)
    end

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

      # Un coaching privé n'est créable que si le coach peut le payer.
      before(:create) do |session|
        needed = ClubRules.current.price_for("coaching_prive")
        missing = needed - session.user.balance.amount
        if missing.positive?
          CreditTransaction.record!(
            user: session.user,
            transaction_type: :manual_adjustment,
            amount: missing
          )
          session.user.balance.reload
        end
      end
    end

    trait :terrain_2 do
      terrain { "Terrain 2" }
    end

    trait :terrain_3 do
      terrain { "Terrain 3" }
    end
  end
end
