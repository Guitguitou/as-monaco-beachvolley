# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::SessionsPeriod do
  let(:now) { Time.find_zone("Europe/Paris").local(2026, 9, 23, 15) }

  def period(name, anchor = nil)
    described_class.new(name, anchor, now: now)
  end

  context "for a week" do
    it "defaults to the current week, from monday to sunday" do
      week = period("week")

      expect(week.range.first).to eq(now.beginning_of_week(:monday))
      expect(week.range.last).to eq(now.end_of_week(:monday))
      expect(week.label).to eq("21/09 – 27/09")
    end

    it "starts on the monday of the given day and links to the weeks around" do
      week = period("week", "2026-09-10")

      expect(week.range.first.to_date).to eq(Date.new(2026, 9, 7))
      expect(week.previous_anchor).to eq("2026-08-31")
      expect(week.next_anchor).to eq("2026-09-14")
    end
  end

  context "for a month" do
    it "covers the given month and links to the months around" do
      month = period("month", "2026-02")

      expect(month.range.first.to_date).to eq(Date.new(2026, 2, 1))
      expect(month.range.last.to_date).to eq(Date.new(2026, 2, 28))
      expect(month.label).to eq(I18n.l(month.range.first, format: :month_and_year))
      expect(month.previous_anchor).to eq("2026-01")
      expect(month.next_anchor).to eq("2026-03")
    end
  end

  context "for a year" do
    it "covers the given year and links to the years around" do
      year = period("year", "2025")

      expect(year.range.first.to_date).to eq(Date.new(2025, 1, 1))
      expect(year.range.last.to_date).to eq(Date.new(2025, 12, 31))
      expect(year.label).to eq("2025")
      expect([ year.previous_anchor, year.next_anchor ]).to eq(%w[2024 2026])
    end

    it "defaults to the current year" do
      expect(period("year").label).to eq("2026")
    end
  end

  it "falls back to the week for an unknown period" do
    unknown = period("decade")

    expect(unknown.name).to eq("week")
    expect(unknown.range.first).to eq(now.beginning_of_week(:monday))
  end
end
