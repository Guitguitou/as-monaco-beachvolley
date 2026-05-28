# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reporting::Revenue do
  let(:revenue_service) { described_class.new(time_zone: 'Europe/Paris') }
  let(:current_time) { Time.zone.parse('2024-01-15 10:00:00') } # Lundi

  before do
    travel_to(current_time)
  end

  after do
    travel_back
  end

  describe '#period_revenues' do
    let!(:user) { create(:user) }
    let!(:week_start) { current_time.beginning_of_week(:monday) }
    let!(:month_start) { current_time.beginning_of_month }
    let!(:year_start) { current_time.beginning_of_year }

    before do
      # Week revenue (in current week)
      create(:credit_purchase,
             user: user,
             status: :paid,
             paid_at: week_start + 1.day,
             amount_cents: 10000) # 100€

      # Month revenue (in month but outside current week)
      create(:credit_purchase,
             user: user,
             status: :paid,
             paid_at: month_start + 2.days, # Early in month, before week
             amount_cents: 20000) # 200€

      # Year revenue (in year but outside current month)
      create(:credit_purchase,
             user: user,
             status: :paid,
             paid_at: year_start + 60.days, # February/March, outside current month
             amount_cents: 50000) # 500€
    end

    it 'calculates revenues for all periods' do
      revenues = revenue_service.period_revenues

      expect(revenues[:week]).to eq(100.0)
      expect(revenues[:month]).to eq(300.0) # 100 (week) + 200 (month only)
      expect(revenues[:year]).to eq(800.0) # 100 + 200 + 500
    end
  end

  describe '#breakdown_by_purchase_type' do
    let!(:user) { create(:user) }
    let!(:credits_pack) { create(:pack, pack_type: :credits, amount_cents: 10000, credits: 100) }
    let(:period_range) { current_time..(current_time + 7.days) }

    before do
      # Credit pack revenue
      create(:credit_purchase,
             user: user,
             pack: credits_pack,
             status: :paid,
             paid_at: current_time + 1.day,
             amount_cents: 10000) # 100€
    end

    it 'breaks down revenue by purchase type' do
      breakdown = revenue_service.breakdown_by_purchase_type(period_range)

      expect(breakdown[:credit_packs]).to eq(100.0)
      expect(breakdown[:licenses]).to eq(0.0) # Not implemented yet
      expect(breakdown[:stages]).to eq(0.0) # Not implemented yet
      expect(breakdown[:total]).to eq(100.0)
    end
  end

  describe '#pack_breakdown_by_type' do
    let!(:user) { create(:user) }
    let!(:stage) { create(:stage) }
    let!(:credits_pack) { create(:pack, pack_type: :credits) }
    let!(:stage_pack) { create(:pack, pack_type: :stage, stage: stage) }
    let!(:licence_pack) { create(:pack, pack_type: :licence) }
    let(:period_range) { current_time..(current_time + 7.days) }

    before do
      create(:credit_purchase,
             user: user,
             pack: credits_pack,
             status: :paid,
             paid_at: current_time + 1.day,
             amount_cents: 10000) # 100€

      create(:credit_purchase,
             user: user,
             pack: stage_pack,
             status: :paid,
             paid_at: current_time + 2.days,
             amount_cents: 20000) # 200€

      create(:credit_purchase,
             user: user,
             pack: licence_pack,
             status: :paid,
             paid_at: current_time + 3.days,
             amount_cents: 30000) # 300€
    end

    it 'breaks down pack revenue by type' do
      breakdown = revenue_service.pack_breakdown_by_type(period_range)

      expect(breakdown['credits']).to eq(100.0)
      expect(breakdown['stage']).to eq(200.0)
      expect(breakdown['licence']).to eq(300.0)
    end
  end

  describe '#session_breakdown_by_type' do
    let!(:user) { create(:user) }
    let!(:coach) do
      coach = create(:user, coach: true)
      coach.balance.update!(amount: 2000) # Enough for private coaching
      coach
    end
    let!(:training_session) { create(:session, session_type: 'entrainement', start_at: current_time + 1.day, end_at: current_time + 1.day + 1.5.hours, user: coach) }
    let!(:free_play_session) { create(:session, session_type: 'jeu_libre', start_at: current_time + 2.days, end_at: current_time + 2.days + 2.hours, user: coach) }
    let!(:private_coaching_session) { create(:session, session_type: 'coaching_prive', start_at: current_time + 3.days, end_at: current_time + 3.days + 1.hour, user: coach) }
    let(:period_range) { current_time..(current_time + 7.days) }

    before do
      create(:credit_transaction,
             user: user,
             session: training_session,
             transaction_type: :training_payment,
             amount: -400) # -4€

      create(:credit_transaction,
             user: user,
             session: free_play_session,
             transaction_type: :free_play_payment,
             amount: -300) # -3€

      # Note: private_coaching_session already created a transaction via callback
      # So no need to create it manually
    end

    it 'breaks down session revenue by type' do
      breakdown = revenue_service.session_breakdown_by_type(period_range)

      expect(breakdown['entrainement']).to eq(4.0)
      expect(breakdown['jeu_libre']).to eq(3.0)
      expect(breakdown['coaching_prive']).to eq(15.0)
    end
  end

  describe '#revenue_evolution' do
    let!(:user) { create(:user) }
    let!(:week_start) { current_time.beginning_of_week(:monday) }
    let!(:previous_week_start) { week_start - 1.week }

    before do
      # Current week revenue
      create(:credit_purchase,
             user: user,
             status: :paid,
             paid_at: week_start + 1.day,
             amount_cents: 10000) # 100€

      # Previous week revenue
      create(:credit_purchase,
             user: user,
             status: :paid,
             paid_at: previous_week_start + 1.day,
             amount_cents: 8000) # 80€
    end

    it 'calculates revenue evolution' do
      evolution = revenue_service.revenue_evolution

      expect(evolution[:week][:current]).to eq(100.0)
      expect(evolution[:week][:previous]).to eq(80.0)
      expect(evolution[:week][:evolution]).to eq(25.0) # (100-80)/80 * 100
    end
  end
end
