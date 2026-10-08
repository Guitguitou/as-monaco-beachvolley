FactoryBot.define do
  factory :tournament do
    title { "Tournoi mixte" }
    starts_on { Date.current + 3.weeks }
    ends_on { starts_on }
    start_time { "10:00" }
    end_time { "16:00" }
    level { "S3" }
    points { 150 }
    price_cents { 3000 }
    registration_link { "https://bvs.example.com/tournoi" }
    terrains { [] }
  end
end
