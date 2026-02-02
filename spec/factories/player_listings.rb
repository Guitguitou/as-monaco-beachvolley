FactoryBot.define do
  factory :player_listing do
    association :user
    listing_type { "disponible" }
    status { "active" }
    date { Date.current }
    starts_at { Time.zone.parse("10:00") }
    ends_at { Time.zone.parse("11:00") }
    notes { "Disponible pour jouer." }
  end
end
