# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reporting::CoachSalaries do
  let(:coach_salaries_service) { described_class.new }
  let(:current_time) { Time.zone.parse('2024-01-15 10:00:00') } # Lundi

  before do
    travel_to(current_time)
    Reporting::CacheService.clear_all
  end

  after do
    travel_back
  end

  describe '#total_for_period' do
    let!(:coach1) { create(:user, coach: true, salary_per_training_cents: 5000) } # 50€
    let!(:coach2) { create(:user, coach: true, salary_per_training_cents: 3000) } # 30€
    let(:period_range) { current_time..(current_time + 7.days) }

    context 'with training sessions in the period' do
      let!(:session1) do
        create(:session,
               session_type: 'entrainement',
               start_at: current_time + 1.day,
               end_at: current_time + 1.day + 1.5.hours,
               user: coach1)
      end
      let!(:session2) do
        create(:session,
               session_type: 'entrainement',
               start_at: current_time + 2.days,
               end_at: current_time + 2.days + 1.5.hours,
               user: coach1)
      end
      let!(:session3) do
        create(:session,
               session_type: 'entrainement',
               start_at: current_time + 3.days,
               end_at: current_time + 3.days + 1.5.hours,
               user: coach2)
      end

      it 'calculates total salaries correctly' do
        total = coach_salaries_service.total_for_period(period_range)

        # coach1: 2 sessions * 50€ = 100€
        # coach2: 1 session * 30€ = 30€
        # Total: 130€
        expect(total).to eq(130.0)
      end
    end

    context 'with no training sessions in period' do
      let(:future_period) { (current_time + 30.days)..(current_time + 37.days) }

      it 'returns zero' do
        total = coach_salaries_service.total_for_period(future_period)

        expect(total).to eq(0.0)
      end
    end
  end

  describe '#breakdown' do
    let!(:coach1) { create(:user, coach: true, salary_per_training_cents: 5000) } # 50€
    let!(:coach2) { create(:user, coach: true, salary_per_training_cents: 3000) } # 30€
    let(:week_range) { current_time..(current_time + 7.days) }
    let(:month_range) { current_time.beginning_of_month..current_time.end_of_month }
    let(:year_range) { current_time.beginning_of_year..current_time.end_of_year }

    before do
      # Week sessions
      create(:session, session_type: 'entrainement', start_at: current_time + 1.day, end_at: current_time + 1.day + 1.5.hours, user: coach1)
      create(:session, session_type: 'entrainement', start_at: current_time + 2.days, end_at: current_time + 2.days + 1.5.hours, user: coach2)

      # Month sessions (outside week)
      create(:session, session_type: 'entrainement', start_at: current_time + 10.days, end_at: current_time + 10.days + 1.5.hours, user: coach1)
      create(:session, session_type: 'entrainement', start_at: current_time + 15.days, end_at: current_time + 15.days + 1.5.hours, user: coach2)
    end

    it 'returns breakdown for all periods' do
      breakdown = coach_salaries_service.breakdown(
        week_range: week_range,
        month_range: month_range,
        year_range: year_range
      )

      expect(breakdown).to be_an(Array)
      expect(breakdown.length).to eq(2) # 2 coaches

      coach1_data = breakdown.find { |data| data[:user] == coach1 }
      coach2_data = breakdown.find { |data| data[:user] == coach2 }

      expect(coach1_data[:week_count]).to eq(1)
      expect(coach1_data[:week_amount]).to eq(50.0)
      expect(coach1_data[:month_count]).to eq(2)
      expect(coach1_data[:month_amount]).to eq(100.0)

      expect(coach2_data[:week_count]).to eq(1)
      expect(coach2_data[:week_amount]).to eq(30.0)
      expect(coach2_data[:month_count]).to eq(2)
      expect(coach2_data[:month_amount]).to eq(60.0)
    end

    it 'sorts by month amount descending' do
      breakdown = coach_salaries_service.breakdown(
        week_range: week_range,
        month_range: month_range,
        year_range: year_range
      )

      expect(breakdown.first[:month_amount]).to be >= breakdown.last[:month_amount]
    end
  end

  describe '#by_coach_for_period' do
    let!(:coach1) { create(:user, coach: true, salary_per_training_cents: 5000) } # 50€
    let!(:coach2) { create(:user, coach: true, salary_per_training_cents: 3000) } # 30€
    let(:period_range) { current_time..(current_time + 7.days) }

    before do
      create(:session, session_type: 'entrainement', start_at: current_time + 1.day, end_at: current_time + 1.day + 1.5.hours, user: coach1)
      create(:session, session_type: 'entrainement', start_at: current_time + 2.days, end_at: current_time + 2.days + 1.5.hours, user: coach1)
      create(:session, session_type: 'entrainement', start_at: current_time + 3.days, end_at: current_time + 3.days + 1.5.hours, user: coach2)
    end

    it 'returns breakdown by coach for the period' do
      breakdown = coach_salaries_service.by_coach_for_period(period_range)

      expect(breakdown).to be_an(Array)
      expect(breakdown.length).to eq(2)

      coach1_data = breakdown.find { |data| data[:user] == coach1 }
      coach2_data = breakdown.find { |data| data[:user] == coach2 }

      expect(coach1_data[:session_count]).to eq(2)
      expect(coach1_data[:total_amount]).to eq(100.0)
      expect(coach1_data[:salary_per_training]).to eq(50.0)

      expect(coach2_data[:session_count]).to eq(1)
      expect(coach2_data[:total_amount]).to eq(30.0)
      expect(coach2_data[:salary_per_training]).to eq(30.0)
    end

    it 'sorts by total amount descending' do
      breakdown = coach_salaries_service.by_coach_for_period(period_range)

      expect(breakdown.first[:total_amount]).to be >= breakdown.last[:total_amount]
    end
  end

  describe '#upcoming_sessions_for_coach' do
    let!(:coach) { create(:user, coach: true) }
      let!(:past_session) do
        create(:session,
               session_type: 'entrainement',
               start_at: current_time - 1.day,
               end_at: current_time - 1.day + 1.5.hours,
               user: coach)
      end
      let!(:upcoming_session1) do
        create(:session,
               session_type: 'entrainement',
               start_at: current_time + 1.day,
               end_at: current_time + 1.day + 1.5.hours,
               user: coach)
      end
      let!(:upcoming_session2) do
        create(:session,
               session_type: 'entrainement',
               start_at: current_time + 2.days,
               end_at: current_time + 2.days + 1.5.hours,
               user: coach)
      end

    it 'returns only upcoming sessions for the coach' do
      upcoming = coach_salaries_service.upcoming_sessions_for_coach(coach)

      expect(upcoming).to include(upcoming_session1)
      expect(upcoming).to include(upcoming_session2)
      expect(upcoming).not_to include(past_session)
    end

    it 'respects the limit parameter' do
      upcoming = coach_salaries_service.upcoming_sessions_for_coach(coach, limit: 1)

      expect(upcoming.count).to eq(1)
    end
  end

  describe '#total_hours_for_coach' do
    let!(:coach) { create(:user, coach: true) }
    let(:period_range) { current_time..(current_time + 7.days) }

    before do
      create(:session,
             session_type: 'entrainement',
             start_at: current_time + 1.day,
             end_at: current_time + 1.day + 1.5.hours,
             user: coach)
      create(:session,
             session_type: 'entrainement',
             start_at: current_time + 2.days,
             end_at: current_time + 2.days + 2.hours,
             user: coach)
    end

    it 'calculates total hours correctly' do
      total_hours = coach_salaries_service.total_hours_for_coach(coach, period_range)

      expect(total_hours).to eq(3.5) # 1.5 + 2.0 hours
    end
  end

  # Ces deux méthodes remplacent le calcul recopié dans UsersController,
  # Coach::TrainingsController et Admin::UsersController.
  describe "#periods_for_coach" do
    let(:solo_coach) { create(:user, coach: true, salary_per_training_cents: 4000) }
    let(:other_coach) { create(:user, coach: true, salary_per_training_cents: 9900) }

    let(:week_range) { Time.zone.today.beginning_of_week..(Time.zone.today.beginning_of_week + 7.days) }
    let(:month_range) { Time.zone.now.beginning_of_month..Time.zone.now.end_of_month }
    let(:year_range) { Time.zone.now.beginning_of_year..Time.zone.now.end_of_year }

    subject(:periods) do
      described_class.new.periods_for_coach(
        solo_coach, week_range: week_range, month_range: month_range, year_range: year_range
      )
    end

    def training_at(time, coach:)
      create(:session, user: coach, session_type: "entrainement", start_at: time, end_at: time + 2.hours)
    end

    it "counts and prices the coach's own trainings" do
      training_at(Time.zone.now.beginning_of_month + 1.day + 9.hours, coach: solo_coach)

      expect(periods[:month][:count]).to eq(1)
      expect(periods[:month][:amount]).to eq(40.0)
      expect(periods[:salary_per_training]).to eq(40.0)
    end

    it "ignores trainings led by another coach" do
      training_at(Time.zone.now.beginning_of_month + 2.days + 9.hours, coach: other_coach)

      expect(periods[:month][:count]).to eq(0)
      expect(periods[:month][:amount]).to eq(0.0)
    end

    it "ignores sessions that are not trainings" do
      time = Time.zone.now.beginning_of_month + 3.days + 9.hours
      create(:session, :jeu_libre, user: solo_coach, start_at: time, end_at: time + 2.hours)

      expect(periods[:month][:count]).to eq(0)
    end

    it "returns zeroes for a coach with no salary set" do
      unpaid = create(:user, coach: true, salary_per_training_cents: 0)
      training_at(Time.zone.now.beginning_of_month + 4.days + 9.hours, coach: unpaid)

      result = described_class.new.periods_for_coach(
        unpaid, week_range: week_range, month_range: month_range, year_range: year_range
      )

      expect(result[:month][:count]).to eq(1)
      expect(result[:month][:amount]).to eq(0.0)
    end

    it "exposes the three periods" do
      expect(periods.keys).to include(:week, :month, :year, :salary_per_training)
    end
  end

  describe "#monthly_history_for_coach" do
    let(:solo_coach) { create(:user, coach: true, salary_per_training_cents: 5000) }

    it "returns one entry per month, oldest first" do
      history = described_class.new.monthly_history_for_coach(solo_coach, months: 12)

      expect(history.size).to eq(12)
      expect(history.last[:month_name]).to eq(I18n.l(Time.zone.today.beginning_of_month, format: :month_and_year))
    end

    it "prices the trainings of each month" do
      time = Time.zone.now.beginning_of_month + 1.day + 9.hours
      2.times do |i|
        slot = time + (i * 4).hours
        create(:session, user: solo_coach, session_type: "entrainement", start_at: slot, end_at: slot + 2.hours)
      end

      current_month = described_class.new.monthly_history_for_coach(solo_coach).last

      expect(current_month[:training_count]).to eq(2)
      expect(current_month[:total_salary]).to eq(100.0)
    end

    it "reports empty months as zero rather than omitting them" do
      history = described_class.new.monthly_history_for_coach(solo_coach, months: 3)

      expect(history.size).to eq(3)
      expect(history.map { |m| m[:training_count] }).to all(eq(0))
    end

    it "localises month names in French" do
      history = described_class.new.monthly_history_for_coach(solo_coach, months: 12)

      expect(history.map { |m| m[:month_name] }.join(" ")).to match(/janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre/)
    end
  end
end
