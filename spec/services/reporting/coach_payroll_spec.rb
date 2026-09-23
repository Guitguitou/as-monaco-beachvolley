# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reporting::CoachPayroll do
  let(:current_time) { Time.zone.parse("2024-01-15 10:00:00") }
  let(:coach) { create(:user, coach: true, salary_per_training_cents: 4000) }

  before { travel_to(current_time) }
  after { travel_back }

  def training_at(time, coach: self.coach, type: "entrainement")
    create(:session, user: coach, session_type: type, start_at: time, end_at: time + 2.hours)
  end

  describe "#periods" do
    let(:ranges) do
      { week: current_time.beginning_of_week..current_time.end_of_week,
        month: current_time.beginning_of_month..current_time.end_of_month,
        year: current_time.beginning_of_year..current_time.end_of_year }
    end

    it "counts and prices the coach's own trainings only" do
      training_at(current_time.beginning_of_month + 1.day + 9.hours)
      training_at(current_time.beginning_of_month + 2.days + 9.hours, coach: create(:user, coach: true))
      training_at(current_time.beginning_of_month + 3.days + 9.hours, type: "jeu_libre")

      periods = described_class.new(coach).periods(ranges)

      expect(periods[:month]).to eq({ count: 1, amount: 40.0 })
      expect(periods[:salary_per_training]).to eq(40.0)
      expect(periods.keys).to contain_exactly(:week, :month, :year, :salary_per_training)
    end

    it "prices nothing for a coach without salary" do
      unpaid = create(:user, coach: true, salary_per_training_cents: 0)
      training_at(current_time.beginning_of_month + 4.days + 9.hours, coach: unpaid)

      expect(described_class.new(unpaid).periods(ranges)[:month]).to eq({ count: 1, amount: 0.0 })
    end
  end

  describe "#current_periods" do
    it "counts this week, month and year" do
      training_at(current_time + 1.day)
      training_at(current_time.beginning_of_month + 24.days)
      training_at(current_time.beginning_of_year + 60.days)

      periods = described_class.new(coach).current_periods

      expect(periods.values_at(:week, :month, :year).map { |period| period[:count] }).to eq([ 1, 2, 3 ])
    end
  end

  describe "#monthly_history" do
    it "gives one entry per month, oldest first, empty months included" do
      2.times { |i| training_at(current_time.beginning_of_month + 1.day + (9 + i * 4).hours) }

      history = described_class.new(coach).monthly_history(months: 3)

      expect(history.map { |month| month[:training_count] }).to eq([ 0, 0, 2 ])
      expect(history.last).to eq({ month_name: I18n.l(current_time.to_date.beginning_of_month, format: :month_and_year),
                                   training_count: 2, total_salary: 80.0 })
    end
  end

  describe "#upcoming_sessions" do
    it "lists the coach's next trainings, soonest first, up to the limit" do
      training_at(current_time - 1.day)
      later = training_at(current_time + 2.days)
      sooner = training_at(current_time + 1.day)

      expect(described_class.new(coach).upcoming_sessions.to_a).to eq([ sooner, later ])
      expect(described_class.new(coach).upcoming_sessions(limit: 1).to_a).to eq([ sooner ])
    end
  end
end
