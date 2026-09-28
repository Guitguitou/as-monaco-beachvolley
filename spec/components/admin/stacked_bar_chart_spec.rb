# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::StackedBarChart do
  let(:chart) { described_class.new(columns: [ { "a" => 300.0, "b" => 100.0 }, { "a" => 150.0 } ], keys: %w[a b]) }

  it "rounds the scale up to readable ticks" do
    expect(chart.ticks.map(&:value)).to eq([ 0, 100, 200, 300, 400 ])
    expect(chart.ticks.first.y).to eq(chart.baseline_y)
  end

  it "stacks segments from the baseline upwards" do
    a, b = chart.segments(0)

    expect(a.y + a.height).to eq(chart.baseline_y)
    expect(b.y + b.height).to be_within(0.001).of(a.y)
    expect(a.height).to be_within(0.001).of(b.height * 3)
  end

  it "skips empty segments" do
    expect(chart.segments(1).map(&:key)).to eq([ "a" ])
  end

  it "keeps a default scale when there is no value" do
    empty = described_class.new(columns: [ {} ], keys: %w[a])

    expect(empty.ticks.last.value).to eq(100)
    expect(empty.segments(0)).to be_empty
  end
end
