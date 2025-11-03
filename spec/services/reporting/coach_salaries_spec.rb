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
end
