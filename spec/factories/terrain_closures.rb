# frozen_string_literal: true

FactoryBot.define do
  factory :terrain_closure do
    transient do
      terrain { "Terrain 1" }
    end

    after(:build) do |closure, evaluator|
      closure.terrain = FactoryHelpers.resolve_terrain(evaluator.terrain)
    end

    starts_on { Time.zone.today }
    ends_on { Time.zone.today + 2.days }
    reason { "Maintenance" }
  end
end
