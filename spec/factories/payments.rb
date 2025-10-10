FactoryBot.define do
  factory :payment do
    user { nil }
    credit_package { nil }
    status { "MyString" }
    amount_cents { 1 }
    sherlock_transaction_id { "MyString" }
    sherlock_response { "MyText" }
  end
end
