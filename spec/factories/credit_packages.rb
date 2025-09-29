FactoryBot.define do
  factory :credit_package do
    name { "MyString" }
    description { "MyText" }
    credits { 1 }
    price_cents { 1 }
    active { false }
  end
end
