# frozen_string_literal: true

FactoryBot.define do
  factory :balance do
    user { nil }
    amount { 1 }
  end
end
