FactoryBot.define do
  factory :player_request do
    association :player_listing
    association :from_user, factory: :user
    to_user { player_listing.user }
    status { "pending" }
    message { "Partant pour jouer ?" }
  end
end
