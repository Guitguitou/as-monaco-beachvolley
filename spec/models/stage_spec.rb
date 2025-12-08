# frozen_string_literal: true

require "rails_helper"

RSpec.describe Stage, type: :model do
  describe "associations" do
    subject(:stage) { create(:stage) }

    it "belongs to main_coach" do
      expect(stage).to respond_to(:main_coach)
    end

    it "belongs to assistant_coach" do
      expect(stage).to respond_to(:assistant_coach)
    end

    it "has many packs" do
      expect(stage).to respond_to(:packs)
      expect(stage.packs).to be_a(ActiveRecord::Associations::CollectionProxy)
    end

    it "has one attached image" do
      expect(stage).to respond_to(:image)
    end
  end

  describe "validations" do
    it "requires title" do
      stage = build(:stage, title: nil)
      expect(stage).not_to be_valid
      expect(stage.errors[:title]).to be_present
    end

    it "requires starts_on" do
      stage = build(:stage, starts_on: nil)
      expect(stage).not_to be_valid
      expect(stage.errors[:starts_on]).to be_present
    end

    it "requires ends_on" do
      stage = build(:stage, ends_on: nil)
      expect(stage).not_to be_valid
      expect(stage.errors[:ends_on]).to be_present
    end

    it "validates price_cents is greater than or equal to 0" do
      stage = build(:stage, price_cents: -1)
      expect(stage).not_to be_valid
      expect(stage.errors[:price_cents]).to be_present
    end

    it "allows nil price_cents" do
      stage = build(:stage, price_cents: nil)
      expect(stage).to be_valid
    end

    it "validates ends_on is after starts_on" do
      stage = build(:stage, starts_on: Date.current + 1.day, ends_on: Date.current)
      expect(stage).not_to be_valid
      expect(stage.errors[:ends_on]).to be_present
    end
  end

  describe "scopes" do
    describe ".ordered_for_players" do
      let(:today) { Date.current }
      let!(:past_stage) { create(:stage, starts_on: today - 10.days, ends_on: today - 5.days) }
      let!(:current_stage) { create(:stage, starts_on: today - 2.days, ends_on: today + 2.days) }
      let!(:upcoming_stage) { create(:stage, starts_on: today + 5.days, ends_on: today + 10.days) }
      let!(:old_past_stage) { create(:stage, starts_on: today - 20.days, ends_on: today - 15.days) }

      it "orders upcoming or current stages by starts_on ascending" do
        result = described_class.ordered_for_players
        current_index = result.index(current_stage)
        upcoming_index = result.index(upcoming_stage)

        expect(current_index).to be < upcoming_index
      end

      it "orders past stages by starts_on descending" do
        result = described_class.ordered_for_players
        past_index = result.index(past_stage)
        old_past_index = result.index(old_past_stage)

        # Past stages should be ordered by starts_on descending (most recent first)
        # old_past_stage starts earlier, so it should come after past_stage
        expect(past_index).to be < old_past_index
      end

      it "places upcoming/current stages before past stages" do
        result = described_class.ordered_for_players
        current_index = result.index(current_stage)
        past_index = result.index(past_stage)

        expect(current_index).to be < past_index
      end
    end
  end

  describe "#current_or_upcoming?" do
    context "when ends_on is in the future" do
      subject(:stage) { create(:stage, starts_on: Date.current - 1.day, ends_on: Date.current + 5.days) }

      it "returns true" do
        expect(stage.current_or_upcoming?).to be true
      end
    end

    context "when ends_on is today" do
      subject(:stage) { create(:stage, starts_on: Date.current - 1.day, ends_on: Date.current) }

      it "returns true" do
        expect(stage.current_or_upcoming?).to be true
      end
    end

    context "when ends_on is in the past" do
      subject(:stage) { create(:stage, starts_on: Date.current - 5.days, ends_on: Date.current - 1.day) }

      it "returns false" do
        expect(stage.current_or_upcoming?).to be false
      end
    end
  end

  describe "#price" do
    context "when price_cents is set" do
      subject(:stage) { create(:stage, price_cents: 5000) }

      it "converts cents to euros" do
        expect(stage.price).to eq(50.0)
      end
    end

    context "when price_cents is nil" do
      subject(:stage) { create(:stage, price_cents: nil) }

      it "returns 0.0" do
        expect(stage.price).to eq(0.0)
      end
    end
  end

  describe "#price=" do
    subject(:stage) { create(:stage) }

    it "converts euros to cents and stores" do
      stage.price = 35.50
      expect(stage.price_cents).to eq(3550)
    end

    it "rounds to nearest cent" do
      stage.price = 35.556
      expect(stage.price_cents).to eq(3556)
    end

    it "handles zero" do
      stage.price = 0
      expect(stage.price_cents).to eq(0)
    end
  end
end
