# frozen_string_literal: true

FactoryBot.define do
  factory :credit_purchase do
    user
    amount_cents { 1000 }
    currency { "EUR" }
    credits { 1000 }
    status { "pending" }

    trait :paid do
      status { "paid" }
      paid_at { Time.current }
    end

    trait :failed do
      status { "failed" }
      failed_at { Time.current }
    end

    trait :cancelled do
      status { "cancelled" }
    end
  end
end
