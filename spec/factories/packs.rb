FactoryBot.define do
  factory :pack do
    name { "MyString" }
    description { "MyText" }
    pack_type { "MyString" }
    amount_cents { 1 }
    credits { 1 }
    active { false }
    position { 1 }
  end
end
