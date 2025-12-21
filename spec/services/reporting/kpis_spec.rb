# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reporting::Kpis do
  let(:time_zone) { 'Europe/Paris' }
  let(:service) { described_class.new(time_zone: time_zone) }
  let(:current_time) { Time.zone.parse('2024-01-15 10:00:00') } # Lundi

  before do
    travel_to(current_time)
    Reporting::CacheService.clear_all
  end

  after do
    travel_back
  end

  describe '#week_kpis' do
    let!(:coach) { create(:user, coach: true, salary_per_training_cents: 5000) } # 50€
    let!(:coach_balance) { create(:balance, user: coach, amount: 2000) } # 20€ de crédits
    let!(:week_start) { current_time.beginning_of_week(:monday) }
    let!(:week_end) { current_time.end_of_week(:monday) }

    context 'with sessions in the current week' do
      let!(:training_session) do
        create(:session, 
               session_type: 'entrainement', 
               start_at: week_start + 1.day,
               end_at: week_start + 1.day + 1.5.hours,
               user: coach)
      end
      let!(:free_play_session) do
        create(:session, 
               session_type: 'jeu_libre', 
               start_at: week_start + 2.days,
               end_at: week_start + 2.days + 2.hours,
               user: coach)
      end
      let!(:private_coaching_session) do
        create(:session, 
               session_type: 'coaching_prive', 
               start_at: week_start + 3.days,
               end_at: week_start + 3.days + 1.hour,
               user: coach)
      end

      it 'returns correct counts for each session type' do
        kpis = service.week_kpis

        expect(kpis[:trainings_count]).to eq(1)
        expect(kpis[:free_plays_count]).to eq(1)
        expect(kpis[:private_coachings_count]).to eq(1)
      end

      it 'calculates coach salaries correctly' do
        kpis = service.week_kpis

        expect(kpis[:coach_salaries]).to eq(50.0) # 1 session * 50€
      end
    end

    context "with late cancellations across periods" do
      let!(:lc_user) { create(:user) }
      let!(:training_session) do
        create(:session,
               session_type: "entrainement",
               start_at: week_start + 1.day,
               end_at: week_start + 1.day + 1.5.hours,
               user: coach)
      end
      let!(:late_cancellation) do
        create(:late_cancellation,
               session: training_session,
               user: lc_user,
               created_at: week_start + 1.day)
      end
      let!(:past_training_session) do
        create(:session,
               session_type: "entrainement",
               start_at: week_start - 10.days,
               end_at: week_start - 10.days + 1.5.hours,
               user: coach)
      end
      let!(:past_late_cancellation) do
        create(:late_cancellation,
               session: past_training_session,
               user: lc_user,
               created_at: week_start - 10.days)
      end

      it "counts late cancellations for all periods" do
        Reporting::CacheService.clear_all
        kpis = service.week_kpis

        expect(kpis[:late_cancellations_count]).to eq(2)
      end
    end

  end


  describe '#upcoming_sessions' do
    let!(:coach) { create(:user, coach: true) }
    let!(:coach_balance) { create(:balance, user: coach, amount: 2000) } # 20€ de crédits
    let!(:upcoming_range) { current_time..(current_time + 7.days) }

    context 'with upcoming sessions' do
      let!(:training_session) do
        create(:session, 
               session_type: 'entrainement', 
               start_at: current_time + 1.day,
               end_at: current_time + 1.day + 1.5.hours,
               user: coach)
      end
      let!(:free_play_session) do
        create(:session, 
               session_type: 'jeu_libre', 
               start_at: current_time + 2.days,
               end_at: current_time + 2.days + 2.hours,
               user: coach)
      end
      let!(:private_coaching_session) do
        create(:session, 
               session_type: 'coaching_prive', 
               start_at: current_time + 3.days,
               end_at: current_time + 3.days + 1.hour,
               user: coach)
      end

      it 'returns upcoming sessions grouped by type' do
        upcoming = service.upcoming_sessions

        expect(upcoming['entrainement']).to include(training_session)
        expect(upcoming['jeu_libre']).to include(free_play_session)
        expect(upcoming['coaching_prive']).to include(private_coaching_session)
      end

      it 'respects the limit parameter' do
        upcoming = service.upcoming_sessions(limit: 1)

        expect(upcoming['entrainement'].count).to eq(1)
        expect(upcoming['jeu_libre'].count).to eq(1)
        expect(upcoming['coaching_prive'].count).to eq(1)
      end
    end
  end

  describe '#capacity_alerts' do
    let!(:coach) { create(:user, coach: true) }
    let!(:coach_balance) { create(:balance, user: coach, amount: 2000) } # 20€ de crédits
    let!(:upcoming_range) { current_time..(current_time + 7.days) }

    context 'with capacity issues' do
      let!(:low_capacity_session) do
        create(:session, 
               session_type: 'entrainement', 
               start_at: current_time + 1.day,
               end_at: current_time + 1.day + 1.5.hours,
               user: coach,
               max_players: 10)
      end
      let!(:high_capacity_session) do
        create(:session, 
               session_type: 'entrainement', 
               start_at: current_time + 2.days,
               end_at: current_time + 2.days + 1.5.hours,
               user: coach,
               max_players: 10)
      end

      before do
        # Create users with credits for registrations
        users = create_list(:user, 11)
        users.each { |user| create(:balance, user: user, amount: 1000) } # 10€ de crédits
        
        # Create registrations to simulate capacity issues
        2.times { |i| create(:registration, session: low_capacity_session, status: :confirmed, user: users[i]) } # 20% capacity
        9.times { |i| create(:registration, session: high_capacity_session, status: :confirmed, user: users[i + 2]) } # 90% capacity
      end

      it 'identifies sessions with capacity alerts' do
        alerts = service.capacity_alerts

        expect(alerts).to include(low_capacity_session)
        expect(alerts).to include(high_capacity_session)
      end
    end
  end

  describe '#recent_late_cancellations' do
    let!(:coach) { create(:user, coach: true) }
    let!(:session) { create(:session, session_type: 'entrainement', start_at: 1.day.from_now, end_at: 1.day.from_now + 1.5.hours, user: coach) }
    let!(:late_cancellation) { create(:late_cancellation, session: session) }

    it 'returns recent late cancellations' do
      cancellations = service.recent_late_cancellations

      expect(cancellations).to include(late_cancellation)
    end

    it 'respects the limit parameter' do
      cancellations = service.recent_late_cancellations(limit: 1)

      expect(cancellations.count).to eq(1)
    end
  end

  describe 'revenue calculation in isolation' do
    let(:isolated_service) { described_class.new(time_zone: 'Europe/Paris') }
    let(:week_start) { current_time.beginning_of_week(:monday) }
    let(:week_end) { current_time.end_of_week(:monday) }
    
    it 'calculates revenue correctly without other sessions' do
      user = create(:user)
      pack = create(:pack, pack_type: 'credits')
      purchase = create(:credit_purchase, 
                        user:, 
                        pack:,
                        amount_cents: 10000, # 100€
                        credits: 10000)
      # Manually set as paid within the week range
      purchase.update_columns(status: :paid, paid_at: week_start + 1.day)

      # Clear cache to ensure fresh calculation
      Reporting::CacheService.clear_all
      kpis = isolated_service.week_kpis

      expect(kpis[:revenue]).to eq(100.0)
    end
  end
end
