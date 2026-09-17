FactoryBot.define do
  factory :registration do
    association :user
    association :session

    # Le modèle applique les règles du parcours d'inscription (crédits, deadline
    # 17h). En fixture on veut poser un état, pas rejouer le parcours : on
    # provisionne le solde et on lève la deadline. Les specs qui vérifient ces
    # règles passent par le contrôleur ou construisent la registration à la main.
    before(:create) do |registration|
      registration.allow_deadline_bypass = true

      needed = registration.required_credits_for(registration.user)
      missing = needed - registration.user.balance.amount
      if missing.positive?
        CreditTransaction.record!(
          user: registration.user,
          session: nil,
          transaction_type: :manual_adjustment,
          amount: missing
        )
        registration.user.balance.reload
      end
    end

    trait :waitlisted do
      status { :waitlisted }
    end
  end
end
