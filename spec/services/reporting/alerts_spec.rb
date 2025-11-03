# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reporting::Alerts do
  let(:alerts_service) { described_class.new(time_zone: 'Europe/Paris') }
  let(:current_time) { Time.zone.parse('2024-01-15 10:00:00') } # Lundi

  before do
    travel_to(current_time)
    Reporting::CacheService.clear_all
  end

  after do
    travel_back
  end

  describe '#all_alerts' do
    let!(:coach) { create(:user, coach: true) }
    let!(:session) { create(:session, session_type: 'entrainement', user: coach) }
    let!(:late_cancellation) { create(:late_cancellation, session: session) }

    it 'returns all types of alerts' do
      alerts = alerts_service.all_alerts

      expect(alerts).to have_key(:late_cancellations)
      expect(alerts).to have_key(:capacity_alerts)
      expect(alerts).to have_key(:low_attendance)
      expect(alerts).to have_key(:upcoming_sessions)
    end
  end

  describe '#late_cancellation_alerts' do
    let!(:coach) { create(:user, coach: true) }
    let!(:session) { create(:session, session_type: 'entrainement', start_at: 1.day.from_now, end_at: 1.day.from_now + 1.5.hours, user: coach) }
    let!(:old_cancellation) do
      create(:late_cancellation, 
             session: session, 
             created_at: current_time - 10.days)
    end
    let!(:recent_cancellation) do
      create(:late_cancellation, 
             session: session, 
             created_at: current_time - 3.days)
    end

    it 'returns only recent late cancellations' do
      alerts = alerts_service.late_cancellation_alerts

      expect(alerts).to include(recent_cancellation)
      expect(alerts).not_to include(old_cancellation)
    end

    it 'respects the limit parameter' do
      alerts = alerts_service.late_cancellation_alerts(limit: 1)

      expect(alerts.count).to eq(1)
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
      let!(:normal_capacity_session) do
        create(:session, 
               session_type: 'entrainement', 
               start_at: current_time + 3.days,
               end_at: current_time + 3.days + 1.5.hours,
               user: coach,
               max_players: 10)
      end

      before do
        # Create users with enough credits for registrations
        users_low = create_list(:user, 2).each { |u| u.balance.update!(amount: 1000) }
        users_high = create_list(:user, 10).each { |u| u.balance.update!(amount: 1000) } # 10/10 = 100% > 90%
        users_normal = create_list(:user, 5).each { |u| u.balance.update!(amount: 1000) }

        # Create registrations to simulate capacity issues
        users_low.each { |u| create(:registration, session: low_capacity_session, user: u, status: :confirmed) }
        users_high.each { |u| create(:registration, session: high_capacity_session, user: u, status: :confirmed) }
        users_normal.each { |u| create(:registration, session: normal_capacity_session, user: u, status: :confirmed) }
      end

      it 'identifies sessions with capacity alerts' do
        alerts = alerts_service.capacity_alerts

        expect(alerts).to include(low_capacity_session)
        expect(alerts).to include(high_capacity_session)
        expect(alerts).not_to include(normal_capacity_session)
      end
    end

    context 'with sessions without max_players' do
      let!(:unlimited_session) do
        create(:session, 
               session_type: 'entrainement', 
               start_at: current_time + 1.day,
               end_at: current_time + 1.day + 1.5.hours,
               user: coach,
               max_players: nil)
      end

      it 'ignores sessions without capacity limits' do
        alerts = alerts_service.capacity_alerts

        expect(alerts).not_to include(unlimited_session)
      end
    end
  end

  describe '#low_attendance_alerts' do
    let!(:coach) { create(:user, coach: true) }
    let!(:upcoming_range) { current_time..(current_time + 3.days) }

    context 'with low attendance sessions' do
      let!(:low_attendance_session) do
        create(:session, 
               session_type: 'entrainement', 
               start_at: current_time + 1.day,
               end_at: current_time + 1.day + 1.5.hours,
               user: coach,
               max_players: 10)
      end
      let!(:normal_attendance_session) do
        create(:session, 
               session_type: 'entrainement', 
               start_at: current_time + 2.days,
               end_at: current_time + 2.days + 1.5.hours,
               user: coach,
               max_players: 10)
      end

      before do
        users_low_att = create_list(:user, 2).each { |u| u.balance.update!(amount: 1000) }
        users_low_att.each { |u| create(:registration, session: low_attendance_session, user: u, status: :confirmed) }
        
        users_normal_att = create_list(:user, 5).each { |u| u.balance.update!(amount: 1000) }
        users_normal_att.each { |u| create(:registration, session: normal_attendance_session, user: u, status: :confirmed) }
      end

      it 'identifies sessions with low attendance' do
        alerts = alerts_service.low_attendance_alerts

        expect(alerts).to include(low_attendance_session)
        expect(alerts).not_to include(normal_attendance_session)
      end
    end
  end

  describe '#upcoming_sessions_alerts' do
    let!(:coach) { create(:user, coach: true) }
    let!(:upcoming_range) { current_time..(current_time + 2.days) }

    context 'with upcoming sessions' do
      let!(:session1) do
        create(:session, 
               session_type: 'entrainement', 
               start_at: current_time + 1.day,
               end_at: current_time + 1.day + 1.5.hours,
               user: coach)
      end
      let!(:session2) do
        create(:session, 
               session_type: 'jeu_libre', 
               start_at: current_time + 2.days,
               end_at: current_time + 2.days + 2.hours,
               user: coach)
      end
      let!(:future_session) do
        create(:session, 
               session_type: 'entrainement', 
               start_at: current_time + 5.days,
               end_at: current_time + 5.days + 1.5.hours,
               user: coach)
      end

      it 'returns only sessions in the next 2 days' do
        alerts = alerts_service.upcoming_sessions_alerts

        expect(alerts).to include(session1)
        expect(alerts).to include(session2)
        expect(alerts).not_to include(future_session)
      end
    end
  end

  describe '#alert_counts' do
    let!(:coach) { create(:user, coach: true) }
    let!(:session) { create(:session, session_type: 'entrainement', user: coach) }
    let!(:late_cancellation) { create(:late_cancellation, session: session) }

    it 'returns counts for all alert types' do
      counts = alerts_service.alert_counts

      expect(counts).to have_key(:late_cancellations)
      expect(counts).to have_key(:capacity_alerts)
      expect(counts).to have_key(:low_attendance)
      expect(counts).to have_key(:upcoming_sessions)
    end
  end

  describe '#critical_alerts' do
    let!(:coach) { create(:user, coach: true) }
    let!(:session) { create(:session, session_type: 'entrainement', start_at: 1.day.from_now, end_at: 1.day.from_now + 1.5.hours, user: coach, terrain: 'Terrain 1') }
    let!(:late_cancellation_today) do
      create(:late_cancellation, 
             session: session, 
             created_at: current_time)
    end
    let!(:session_starting_soon) do
      create(:session, 
             session_type: 'entrainement', 
             start_at: current_time + 1.hour,
             end_at: current_time + 1.hour + 1.5.hours,
             user: coach,
             terrain: 'Terrain 2')
    end
    let!(:empty_session) do
      create(:session, 
             session_type: 'entrainement', 
             start_at: current_time + 1.day,
             end_at: current_time + 1.day + 1.5.hours,
             user: coach,
             max_players: 10,
             terrain: 'Terrain 3')
    end

    it 'returns critical alerts' do
      critical = alerts_service.critical_alerts

      expect(critical).to have_key(:late_cancellations_today)
      expect(critical).to have_key(:sessions_starting_soon)
      expect(critical).to have_key(:empty_sessions)
    end
  end
end
