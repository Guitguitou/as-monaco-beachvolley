# frozen_string_literal: true

require "rails_helper"

RSpec.describe TerrainClosure, type: :model do
  describe "validations" do
    it "requires ends_on >= starts_on" do
      c = build(:terrain_closure, starts_on: Date.current, ends_on: Date.current - 1.day)
      expect(c).not_to be_valid
      expect(c.errors[:ends_on]).to be_present
    end

    it "rejects unknown terrain strings" do
      c = build(:terrain_closure, terrain: "Terrain 99")
      expect(c).not_to be_valid
      expect(c.errors[:terrain]).to be_present
    end
  end

  describe ".for_date" do
    it "returns closures active on that calendar day" do
      create(:terrain_closure, terrain: "Terrain 2", starts_on: Date.new(2030, 3, 1), ends_on: Date.new(2030, 3, 10))
      expect(TerrainClosure.for_date(Date.new(2030, 3, 5)).count).to eq(1)
      expect(TerrainClosure.for_date(Date.new(2030, 2, 28))).to be_empty
    end
  end

  describe ".intersecting_range" do
    it "returns closures overlapping the week window" do
      create(:terrain_closure, terrain: "Terrain 1", starts_on: Date.new(2030, 3, 3), ends_on: Date.new(2030, 3, 5))
      week_start = Date.new(2030, 3, 2) # Monday
      week_end = week_start + 6.days
      expect(TerrainClosure.intersecting_range(week_start, week_end)).to be_present
    end

    it "excludes closures entirely before the range" do
      create(:terrain_closure, terrain: "Terrain 3", starts_on: Date.new(2020, 1, 1), ends_on: Date.new(2020, 1, 2))
      expect(TerrainClosure.intersecting_range(Date.new(2030, 1, 1), Date.new(2030, 1, 7))).to be_empty
    end
  end

  describe ".covers?" do
    it "is true when terrain and date fall in the closure range" do
      create(:terrain_closure, terrain: "Terrain 2", starts_on: Date.new(2030, 4, 1), ends_on: Date.new(2030, 4, 7))
      expect(TerrainClosure.covers?(terrain: "Terrain 2", date: Date.new(2030, 4, 3))).to be true
      expect(TerrainClosure.covers?(terrain: "Terrain 1", date: Date.new(2030, 4, 3))).to be false
    end
  end
end
