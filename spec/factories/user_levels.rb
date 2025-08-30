FactoryBot.define do
  factory :user_level do
    association :user
    association :level
  end
end
