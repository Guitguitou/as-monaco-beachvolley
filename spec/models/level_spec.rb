# frozen_string_literal: true

require "rails_helper"

RSpec.describe Level, type: :model do
  describe "enum :gender" do
    it "has the correct enum values" do
      expect(described_class.genders.keys).to contain_exactly("male", "female", "mixed")
    end
  end

  describe "#display_name" do
    context "when gender is male" do
      subject(:level) { described_class.new(name: "A", gender: "male") }

      it "appends M to the name" do
        expect(level.display_name).to eq("A M")
      end
    end

    context "when gender is female" do
      subject(:level) { described_class.new(name: "B", gender: "female") }

      it "appends F to the name" do
        expect(level.display_name).to eq("B F")
      end
    end

    context "when gender is mixed" do
      subject(:level) { described_class.new(name: "C", gender: "mixed") }

      it "appends X to the name" do
        expect(level.display_name).to eq("C X")
      end
    end

    context "when gender is not set" do
      subject(:level) { described_class.new(name: "D") }

      it "returns only the name" do
        expect(level.display_name).to eq("D")
      end
    end
  end
end
