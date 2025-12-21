# frozen_string_literal: true

FactoryBot.define do
  factory :user_level do
    association :user
    association :level
  end
end
