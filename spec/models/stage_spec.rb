require "rails_helper"

RSpec.describe Stage, type: :model do
  describe "validations" do
    it "is invalid when ends_on is before starts_on" do
      stage = build(:stage, starts_on: Date.current + 10.days, ends_on: Date.current + 5.days)

      expect(stage).not_to be_valid
      expect(stage.errors[:ends_on]).to include("doit être après la date de début")
    end
  end

  describe "#price and #price=" do
    it "stores euros as cents and reads euros" do
      stage = build(:stage)
      stage.price = 123.45

      expect(stage.price_cents).to eq(12_345)
      expect(stage.price).to eq(123.45)
    end
  end

  describe ".ordered_for_players" do
    around do |example|
      travel_to(Time.zone.parse("2026-04-09 10:00")) { example.run }
    end

    it "returns upcoming/current first, then past" do
      past = create(:stage, title: "Past", starts_on: Date.current - 20.days, ends_on: Date.current - 10.days)
      current = create(:stage, title: "Current", starts_on: Date.current - 1.day, ends_on: Date.current + 1.day)
      upcoming = create(:stage, title: "Upcoming", starts_on: Date.current + 3.days, ends_on: Date.current + 5.days)

      result = Stage.ordered_for_players

      expect(result).to include(current, upcoming, past)
      expect(result.index(current)).to be < result.index(past)
      expect(result.index(upcoming)).to be < result.index(past)
    end
  end
end
