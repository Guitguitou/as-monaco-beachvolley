# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reporting::Kpis do
  let(:time_zone) { 'Europe/Paris' }
  let(:kpis_service) { described_class.new(time_zone: time_zone) }
  let(:current_time) { Time.zone.parse('2024-01-15 10:00:00') } # Lundi

  before do
    travel_to(current_time)
  end

  after do
    travel_back
  end

  describe '#week_kpis' do
    let!(:coach) { create(:user, coach: true, salary_per_training_cents: 5000) } # 50€
    let!(:week_start) { current_time.beginning_of_week(:monday) }
    let!(:week_end) { current_time.end_of_week(:monday) }

    context 'with sessions in the current week' do
      let!(:training_session) do
        create(:session, 
               session_type: 'entrainement', 
               start_at: week_start + 1.day,
               user: coach)
      end
      let!(:free_play_session) do
        create(:session, 
               session_type: 'jeu_libre', 
               start_at: week_start + 2.days,
               user: coach)
      end
      let!(:private_coaching_session) do
        create(:session, 
               session_type: 'coaching_prive', 
               start_at: week_start + 3.days,
               user: coach)
      end

      it 'returns correct counts for each session type' do
        kpis = kpis_service.week_kpis

        expect(kpis[:trainings_count]).to eq(1)
        expect(kpis[:free_plays_count]).to eq(1)
        expect(kpis[:private_coachings_count]).to eq(1)
      end

      it 'calculates coach salaries correctly' do
        kpis = kpis_service.week_kpis

        expect(kpis[:coach_salaries]).to eq(50.0) # 1 session * 50€
      end
    end

    context 'with late cancellations' do
      let!(:session) { create(:session, session_type: 'entrainement', start_at: week_start + 1.day) }
      let!(:late_cancellation) { create(:late_cancellation, session: session) }

      it 'counts late cancellations' do
        kpis = kpis_service.week_kpis

        expect(kpis[:late_cancellations_count]).to eq(1)
      end
    end

    context 'with revenue' do
      let!(:user) { create(:user) }
      let!(:session) { create(:session, session_type: 'entrainement', start_at: week_start + 1.day) }
      let!(:credit_purchase) do
        create(:credit_purchase, 
               user: user, 
               status: :paid, 
               paid_at: week_start + 1.day,
               amount_cents: 10000) # 100€
      end

      it 'calculates revenue correctly' do
        kpis = kpis_service.week_kpis

        expect(kpis[:revenue]).to eq(100.0)
      end
    end
  end

  describe '#upcoming_sessions' do
    let!(:coach) { create(:user, coach: true) }
    let!(:upcoming_range) { current_time..(current_time + 7.days) }

    context 'with upcoming sessions' do
      let!(:training_session) do
        create(:session, 
               session_type: 'entrainement', 
               start_at: current_time + 1.day,
               user: coach)
      end
      let!(:free_play_session) do
        create(:session, 
               session_type: 'jeu_libre', 
               start_at: current_time + 2.days,
               user: coach)
      end
      let!(:private_coaching_session) do
        create(:session, 
               session_type: 'coaching_prive', 
               start_at: current_time + 3.days,
               user: coach)
      end

      it 'returns upcoming sessions grouped by type' do
        upcoming = kpis_service.upcoming_sessions

        expect(upcoming[:trainings]).to include(training_session)
        expect(upcoming[:free_plays]).to include(free_play_session)
        expect(upcoming[:private_coachings]).to include(private_coaching_session)
      end

      it 'respects the limit parameter' do
        upcoming = kpis_service.upcoming_sessions(limit: 1)

        expect(upcoming[:trainings].count).to eq(1)
        expect(upcoming[:free_plays].count).to eq(1)
        expect(upcoming[:private_coachings].count).to eq(1)
      end
    end
  end

  describe '#capacity_alerts' do
    let!(:coach) { create(:user, coach: true) }
    let!(:upcoming_range) { current_time..(current_time + 7.days) }

    context 'with capacity issues' do
      let!(:low_capacity_session) do
        create(:session, 
               session_type: 'entrainement', 
               start_at: current_time + 1.day,
               user: coach,
               max_players: 10)
      end
      let!(:high_capacity_session) do
        create(:session, 
               session_type: 'entrainement', 
               start_at: current_time + 2.days,
               user: coach,
               max_players: 10)
      end

      before do
        # Create registrations to simulate capacity issues
        create_list(:registration, 2, session: low_capacity_session, status: :confirmed) # 20% capacity
        create_list(:registration, 9, session: high_capacity_session, status: :confirmed) # 90% capacity
      end

      it 'identifies sessions with capacity alerts' do
        alerts = kpis_service.capacity_alerts

        expect(alerts).to include(low_capacity_session)
        expect(alerts).to include(high_capacity_session)
      end
    end
  end

  describe '#recent_late_cancellations' do
    let!(:coach) { create(:user, coach: true) }
    let!(:session) { create(:session, session_type: 'entrainement', user: coach) }
    let!(:late_cancellation) { create(:late_cancellation, session: session) }

    it 'returns recent late cancellations' do
      cancellations = kpis_service.recent_late_cancellations

      expect(cancellations).to include(late_cancellation)
    end

    it 'respects the limit parameter' do
      cancellations = kpis_service.recent_late_cancellations(limit: 1)

      expect(cancellations.count).to eq(1)
    end
  end
end
