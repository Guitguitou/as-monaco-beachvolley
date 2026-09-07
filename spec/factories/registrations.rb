FactoryBot.define do
  factory :registration do
    association :user
    association :session

    trait :waitlisted do
      status { :waitlisted }
    end
  end
end
