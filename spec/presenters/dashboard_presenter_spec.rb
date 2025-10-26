# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::DashboardPresenter do
  let(:presenter) { described_class.new }
  let(:coach) { create(:user, coach: true, salary_per_training_cents: 5000) }
  let(:another_coach) { create(:user, coach: true, salary_per_training_cents: 3000) }
  let(:user) { create(:user) }
  
  before do
    # Give coaches enough credits for private coaching
    coach.balance.update!(amount: 2000)
    another_coach.balance.update!(amount: 2000)
  end

  describe '#upcoming_trainings_for_week' do
    let(:week_start) { Time.zone.now.beginning_of_week }
    let!(:training_this_week) { create(:session, session_type: 'entrainement', start_at: week_start + 2.days + 10.hours, end_at: week_start + 2.days + 12.hours, user: coach) }
    let!(:training_next_week) { create(:session, session_type: 'entrainement', start_at: week_start + 8.days + 10.hours, end_at: week_start + 8.days + 12.hours, user: coach, terrain: 'Terrain 2') }
    let!(:free_play_this_week) { create(:session, session_type: 'jeu_libre', start_at: week_start + 3.days + 10.hours, end_at: week_start + 3.days + 12.hours, user: coach, terrain: 'Terrain 3') }

    it 'returns only trainings for the specified week' do
      result = presenter.upcoming_trainings_for_week(week_start)
      expect(result).to include(training_this_week)
      expect(result).not_to include(training_next_week)
      expect(result).not_to include(free_play_this_week)
    end

    it 'orders by start_at' do
      training_1 = create(:session, session_type: 'entrainement', start_at: week_start + 5.days + 10.hours, end_at: week_start + 5.days + 12.hours, user: coach, terrain: 'Terrain 2')
      training_2 = create(:session, session_type: 'entrainement', start_at: week_start + 1.day + 10.hours, end_at: week_start + 1.day + 12.hours, user: coach, terrain: 'Terrain 3')
      
      result = presenter.upcoming_trainings_for_week(week_start)
      expect(result.first).to eq(training_2)
      expect(result.last).to eq(training_1)
    end
  end

  describe '#upcoming_free_plays' do
    let!(:upcoming_free_play) { create(:session, session_type: 'jeu_libre', start_at: 1.day.from_now + 10.hours, end_at: 1.day.from_now + 12.hours, user: coach) }
    let!(:past_free_play) { create(:session, session_type: 'jeu_libre', start_at: 1.day.ago + 10.hours, end_at: 1.day.ago + 12.hours, user: coach, terrain: 'Terrain 2') }
    let!(:upcoming_training) { create(:session, session_type: 'entrainement', start_at: 1.day.from_now + 14.hours, end_at: 1.day.from_now + 16.hours, user: coach, terrain: 'Terrain 3') }

    it 'returns only upcoming free plays' do
      result = presenter.upcoming_free_plays
      expect(result).to include(upcoming_free_play)
      expect(result).not_to include(past_free_play)
      expect(result).not_to include(upcoming_training)
    end
  end

  describe '#upcoming_private_coachings' do
    let!(:upcoming_coaching) { create(:session, session_type: 'coaching_prive', start_at: 1.day.from_now + 10.hours, end_at: 1.day.from_now + 12.hours, user: coach) }
    let!(:past_coaching) { create(:session, session_type: 'coaching_prive', start_at: 1.day.ago + 10.hours, end_at: 1.day.ago + 12.hours, user: another_coach, terrain: 'Terrain 2') }
    let!(:upcoming_training) { create(:session, session_type: 'entrainement', start_at: 1.day.from_now + 14.hours, end_at: 1.day.from_now + 16.hours, user: coach, terrain: 'Terrain 3') }

    it 'returns only upcoming private coachings' do
      result = presenter.upcoming_private_coachings
      expect(result).to include(upcoming_coaching)
      expect(result).not_to include(past_coaching)
      expect(result).not_to include(upcoming_training)
    end
  end

  describe '#current_month_revenue' do
    let(:month_start) { Time.zone.now.beginning_of_month }
    let(:month_end) { Time.zone.now.end_of_month }
    let!(:training_payment) { create(:credit_transaction, user: user, transaction_type: 'training_payment', amount: -400, created_at: month_start + 1.day) }
    let!(:free_play_payment) { create(:credit_transaction, user: user, transaction_type: 'free_play_payment', amount: -300, created_at: month_start + 2.days) }
    let!(:private_coaching_payment) { create(:credit_transaction, user: user, transaction_type: 'private_coaching_payment', amount: -1500, created_at: month_start + 3.days) }
    let!(:refund) { create(:credit_transaction, user: user, transaction_type: 'refund', amount: 200, created_at: month_start + 4.days) }
    let!(:purchase) { create(:credit_transaction, user: user, transaction_type: 'purchase', amount: 1000, created_at: month_start + 5.days) }
    let!(:old_payment) { create(:credit_transaction, user: user, transaction_type: 'training_payment', amount: -400, created_at: 1.month.ago) }

    it 'returns the net revenue (payments - refunds) for the current month as positive revenue' do
      result = presenter.current_month_revenue
      # payments: 400 + 300 + 1500 = 2150, refund: 200
      # net revenue: 2150 - 200 = 1950
      expected_revenue = 400 + 300 + 1500 - 200
      expect(result).to eq(expected_revenue)
    end

    it 'excludes non-revenue transactions like purchases' do
      result = presenter.current_month_revenue
      # purchase of 1000 should not affect revenue calculation
      expect(result).to eq(1950) # same as above test
    end

    it 'excludes transactions from other months' do
      result = presenter.current_month_revenue
      # old_payment from previous month should not be included
      expect(result).to eq(1950) # same as above test
    end
  end

  describe '#coach_salary_for_period' do
    let(:period_start) { Time.zone.now.beginning_of_week }
    let(:period_end) { period_start + 7.days }
    let!(:training_1) { create(:session, session_type: 'entrainement', start_at: period_start + 1.day + 10.hours, end_at: period_start + 1.day + 12.hours, user: coach) }
    let!(:training_2) { create(:session, session_type: 'entrainement', start_at: period_start + 2.days + 10.hours, end_at: period_start + 2.days + 12.hours, user: coach, terrain: 'Terrain 2') }
    let!(:training_3) { create(:session, session_type: 'entrainement', start_at: period_start + 3.days + 10.hours, end_at: period_start + 3.days + 12.hours, user: another_coach, terrain: 'Terrain 3') }
    let!(:training_outside_period) { create(:session, session_type: 'entrainement', start_at: period_start + 8.days + 10.hours, end_at: period_start + 8.days + 12.hours, user: coach) }
    let!(:free_play) { create(:session, session_type: 'jeu_libre', start_at: period_start + 4.days + 10.hours, end_at: period_start + 4.days + 12.hours, user: coach) }

    it 'calculates total salary for coaches based on their training count in the period' do
      result = presenter.coach_salary_for_period(period_start..period_end)
      # coach: 2 trainings * 50€ = 100€, another_coach: 1 training * 30€ = 30€
      expected_salary = 100 + 30
      expect(result).to eq(expected_salary)
    end
  end

  describe '#coach_salary_breakdown' do
    let(:week_start) { Time.zone.now.beginning_of_week }
    let(:month_start) { Time.zone.now.beginning_of_month }
    let(:year_start) { Time.zone.now.beginning_of_year }
    
    let!(:week_training) { create(:session, session_type: 'entrainement', start_at: week_start + 1.day + 10.hours, end_at: week_start + 1.day + 12.hours, user: coach) }
    let!(:month_training) { create(:session, session_type: 'entrainement', start_at: month_start + 15.days + 10.hours, end_at: month_start + 15.days + 12.hours, user: coach, terrain: 'Terrain 2') }
    let!(:year_training) { create(:session, session_type: 'entrainement', start_at: year_start + 30.days + 10.hours, end_at: year_start + 30.days + 12.hours, user: coach, terrain: 'Terrain 3') }
    let!(:another_week_training) { create(:session, session_type: 'entrainement', start_at: week_start + 2.days + 10.hours, end_at: week_start + 2.days + 12.hours, user: another_coach) }

    it 'returns breakdown with counts and amounts for each coach' do
      result = presenter.coach_salary_breakdown(
        week_range: week_start..(week_start + 7.days),
        month_range: month_start..month_start.end_of_month,
        year_range: year_start..year_start.end_of_year
      )

      expect(result).to be_an(Array)
      expect(result.length).to eq(2) # coach and another_coach

      coach_data = result.find { |data| data[:user] == coach }
      expect(coach_data[:week_count]).to eq(1) # only week_training
      expect(coach_data[:week_amount]).to eq(50.0) # 1 * 50€
      expect(coach_data[:month_count]).to eq(2) # week_training + month_training (both in same month)
      expect(coach_data[:month_amount]).to eq(100.0) # 2 * 50€
      expect(coach_data[:year_count]).to eq(3) # week_training + month_training + year_training
      expect(coach_data[:year_amount]).to eq(150.0) # 3 * 50€

      another_coach_data = result.find { |data| data[:user] == another_coach }
      expect(another_coach_data[:week_count]).to eq(1)
      expect(another_coach_data[:week_amount]).to eq(30.0) # 1 * 30€
    end

    it 'sorts by month_amount descending' do
      result = presenter.coach_salary_breakdown(
        week_range: week_start..(week_start + 7.days),
        month_range: month_start..month_start.end_of_month,
        year_range: year_start..year_start.end_of_year
      )

      expect(result.first[:month_amount]).to be >= result.last[:month_amount]
    end
  end

  describe '#recent_late_cancellations' do
    let!(:training) { create(:session, session_type: 'entrainement', start_at: 1.day.from_now + 10.hours, end_at: 1.day.from_now + 12.hours, user: coach) }
    let!(:free_play) { create(:session, session_type: 'jeu_libre', start_at: 1.day.from_now + 14.hours, end_at: 1.day.from_now + 16.hours, user: coach, terrain: 'Terrain 2') }
    let!(:late_cancellation_training) { create(:late_cancellation, session: training, user: user) }
    let!(:late_cancellation_free_play) { create(:late_cancellation, session: free_play, user: user) }

    it 'returns only late cancellations for trainings' do
      result = presenter.recent_late_cancellations
      expect(result).to include(late_cancellation_training)
      expect(result).not_to include(late_cancellation_free_play)
    end

    it 'includes user and session associations' do
      result = presenter.recent_late_cancellations
      expect(result.first.association(:user)).to be_loaded
      expect(result.first.association(:session)).to be_loaded
    end
  end

  describe '#late_cancellation_counts' do
    let!(:training) { create(:session, session_type: 'entrainement', start_at: 1.day.from_now + 10.hours, end_at: 1.day.from_now + 12.hours, user: coach) }
    let!(:free_play) { create(:session, session_type: 'jeu_libre', start_at: 1.day.from_now + 14.hours, end_at: 1.day.from_now + 16.hours, user: coach, terrain: 'Terrain 2') }
    let!(:late_cancellation_1) { create(:late_cancellation, session: training, user: user) }
    let!(:late_cancellation_2) { create(:late_cancellation, session: training, user: user) }
    let!(:late_cancellation_free_play) { create(:late_cancellation, session: free_play, user: user) }

    it 'returns count of late cancellations per user for trainings only' do
      result = presenter.late_cancellation_counts
      expect(result[user.id]).to eq(2)
    end
  end

  describe 'time helpers' do
    it 'returns correct week start' do
      expect(presenter.week_start).to eq(Time.zone.now.beginning_of_week)
    end

    it 'returns correct month start' do
      expect(presenter.month_start).to eq(Time.zone.now.beginning_of_month)
    end

    it 'returns correct year start' do
      expect(presenter.year_start).to eq(Time.zone.now.beginning_of_year)
    end
  end

  describe 'charges and revenue calculations' do
    let(:week_start) { Time.zone.now.beginning_of_week }
    let(:month_start) { Time.zone.now.beginning_of_month }
    let!(:training) { create(:session, session_type: 'entrainement', start_at: week_start + 1.day + 10.hours, end_at: week_start + 1.day + 12.hours, user: coach) }
    let!(:payment) { create(:credit_transaction, user: user, transaction_type: 'training_payment', amount: -400, created_at: week_start + 1.day) }
    let!(:refund) { create(:credit_transaction, user: user, transaction_type: 'refund', amount: 200, created_at: week_start + 2.days) }

    describe '#weekly_charges' do
      it 'calculates weekly charges (coach salaries + refunds)' do
        result = presenter.weekly_charges
        # coach salary: 1 training * 50€ = 50€
        # refunds: 200 credits / 100 = 2€
        # total: 50 + 2 = 52€
        expect(result).to eq(52.0)
      end
    end

    describe '#monthly_charges' do
      it 'calculates monthly charges (coach salaries + refunds)' do
        result = presenter.monthly_charges
        # coach salary: 1 training * 50€ = 50€
        # refunds: 200 credits / 100 = 2€
        # total: 50 + 2 = 52€
        expect(result).to eq(52.0)
      end
    end

    describe '#weekly_revenue' do
      it 'calculates weekly revenue from payments' do
        result = presenter.weekly_revenue
        # payment: -400, so revenue = 400€
        expect(result).to eq(400.0)
      end
    end

    describe '#monthly_revenue' do
      it 'calculates monthly revenue from payments' do
        result = presenter.monthly_revenue
        # payment: -400, so revenue = 400€
        expect(result).to eq(400.0)
      end
    end

    describe '#weekly_net_profit' do
      it 'calculates weekly net profit (revenue - charges)' do
        result = presenter.weekly_net_profit
        # revenue: 400€, charges: 52€, profit: 298€
        expect(result).to eq(298.0)
      end
    end

    describe '#monthly_net_profit' do
      it 'calculates monthly net profit (revenue - charges)' do
        result = presenter.monthly_net_profit
        # revenue: 400€, charges: 52€, profit: 298€
        expect(result).to eq(298.0)
      end
    end

    describe '#charges_breakdown' do
      it 'returns breakdown of charges for a period' do
        period_range = week_start..(week_start + 7.days)
        result = presenter.charges_breakdown(period_range)
        
        expect(result[:coach_salaries]).to eq(50.0)
        expect(result[:refunds]).to eq(2.0)
        expect(result[:total]).to eq(52.0)
      end
    end

    describe '#revenue_breakdown' do
      it 'returns revenue for a period' do
        period_range = week_start..(week_start + 7.days)
        result = presenter.revenue_breakdown(period_range)
        
        expect(result).to eq(400.0)
      end
    end
  end
end
