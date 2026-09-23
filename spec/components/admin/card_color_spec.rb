# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::CardColor do
  it "gives the tinted background and text classes of a card color" do
    expect(described_class.classes("orange")).to eq("bg-orange-50 text-orange-600")
    expect(described_class.classes("yellow")).to eq("bg-yellow-50 text-yellow-600")
  end

  it "falls back to gray for an unknown color" do
    expect(described_class.classes("pink")).to eq("bg-gray-50 text-gray-600")
  end
end
