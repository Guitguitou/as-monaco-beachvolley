# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reporting::CurrentPeriods do
  it "gives this week (monday to the next monday), this month and this year" do
    now = Time.zone.local(2024, 1, 17, 10)

    ranges = described_class.ranges(now: now)

    expect(ranges[:week]).to eq(Date.new(2024, 1, 15)..Date.new(2024, 1, 22))
    expect(ranges[:month]).to eq(now.beginning_of_month..now.end_of_month)
    expect(ranges[:year]).to eq(now.beginning_of_year..now.end_of_year)
  end
end
