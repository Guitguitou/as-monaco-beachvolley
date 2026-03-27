# frozen_string_literal: true

FactoryBot.define do
  factory :terrain_closure do
    terrain { "Terrain 1" }
    starts_on { Time.zone.today }
    ends_on { Time.zone.today + 2.days }
    reason { "Maintenance" }
  end
end
