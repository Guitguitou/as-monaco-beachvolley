# frozen_string_literal: true

FactoryBot.define do
  factory :credit_transaction do
    user { nil }
    session { nil }
    transaction_type { 1 }
    amount { 1 }
  end
end
