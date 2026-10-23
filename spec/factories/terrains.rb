# frozen_string_literal: true

FactoryBot.define do
  factory :terrain do
    sequence(:name) { |n| "Court #{n}" }
    sequence(:position) { |n| n }
  end
end
