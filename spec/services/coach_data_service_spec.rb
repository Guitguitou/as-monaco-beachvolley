# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CoachDataService, type: :service do
  let(:coach) { create(:user, :coach, salary_per_training: 50) }
  let(:level) { create(:level) }

  describe '#training_counts' do
    it 'returns counts for week, month and year' do
      # Create trainings in different periods
      travel_to(Time.zone.parse('2024-11-15 14:00:00'))

      # Week training
      create(:session,
             session_type: 'entrainement',
             user: coach,
             start_at: Time.zone.parse('2024-11-11 19:00:00'))

      # Month training
      create(:session,
             session_type: 'entrainement',
             user: coach,
             start_at: Time.zone.parse('2024-11-05 19:00:00'))

      # Year training
      create(:session,
             session_type: 'entrainement',
             user: coach,
             start_at: Time.zone.parse('2024-06-15 19:00:00'))

      service = CoachDataService.new(coach)
      counts = service.training_counts

      expect(counts[:week]).to eq(1)
      expect(counts[:month]).to eq(2)
      expect(counts[:year]).to eq(3)

      travel_back
    end
  end

  describe '#salaries' do
    it 'calculates salaries based on training counts' do
      travel_to(Time.zone.parse('2024-11-15 14:00:00'))

      create(:session,
             session_type: 'entrainement',
             user: coach,
             start_at: Time.zone.parse('2024-11-11 19:00:00'))

      service = CoachDataService.new(coach)
      salaries = service.salaries

      expect(salaries[:week]).to eq(50.0)
      expect(salaries[:month]).to eq(50.0)
      expect(salaries[:year]).to eq(50.0)

      travel_back
    end
  end

  describe '#past_trainings' do
    it 'returns past trainings ordered by start_at desc' do
      past1 = create(:session,
                     session_type: 'entrainement',
                     user: coach,
                     start_at: 2.days.ago)
      past2 = create(:session,
                     session_type: 'entrainement',
                     user: coach,
                     start_at: 1.day.ago)

      service = CoachDataService.new(coach)
      past_trainings = service.past_trainings

      expect(past_trainings).to eq([ past2, past1 ])
    end
  end

  describe '#upcoming_trainings' do
    it 'returns upcoming trainings ordered by start_at asc' do
      future1 = create(:session,
                       session_type: 'entrainement',
                       user: coach,
                       start_at: 1.day.from_now)
      future2 = create(:session,
                       session_type: 'entrainement',
                       user: coach,
                       start_at: 2.days.from_now)

      service = CoachDataService.new(coach)
      upcoming_trainings = service.upcoming_trainings

      expect(upcoming_trainings).to eq([ future1, future2 ])
    end
  end

  describe '#monthly_salary_data' do
    it 'returns monthly salary data for the specified number of months' do
      travel_to(Time.zone.parse('2024-11-15 14:00:00'))

      # Create training in current month
      create(:session,
             session_type: 'entrainement',
             user: coach,
             start_at: Time.zone.parse('2024-11-10 19:00:00'))

      service = CoachDataService.new(coach)
      data = service.monthly_salary_data(months: 3)

      expect(data.length).to eq(3)
      expect(data.last[:training_count]).to eq(1)
      expect(data.last[:total_salary]).to eq(50)

      travel_back
    end
  end
end
