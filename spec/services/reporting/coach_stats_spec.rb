# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reporting::CoachStats do
  let(:coach1) { create(:user, :coach, first_name: 'John', last_name: 'Doe', salary_per_training_cents: 5000) }
  let(:coach2) { create(:user, :coach, first_name: 'Jane', last_name: 'Smith', salary_per_training_cents: 6000) }
  let(:regular_user) { create(:user) }

  describe '#active_coaches' do
    it 'returns coaches who have conducted at least one training session' do
      create(:session, :entrainement, user: coach1, start_at: 1.month.ago)
      create(:session, :entrainement, user: coach2, start_at: 2.months.ago)
      
      stats = described_class.new
      coaches = stats.active_coaches
      
      expect(coaches).to include(coach1, coach2)
      expect(coaches).not_to include(regular_user)
    end

    it 'excludes coaches who have not conducted any training sessions' do
      create(:session, :entrainement, user: coach1, start_at: 1.month.ago)
      
      stats = described_class.new
      coaches = stats.active_coaches
      
      expect(coaches).to include(coach1)
      expect(coaches).not_to include(coach2)
    end

    it 'excludes non-training sessions' do
      create(:session, :jeu_libre, user: coach1, start_at: 1.month.ago)
      
      stats = described_class.new
      coaches = stats.active_coaches
      
      expect(coaches).not_to include(coach1)
    end

    it 'orders coaches by first_name and last_name' do
      create(:session, :entrainement, user: coach2, start_at: 1.month.ago)
      create(:session, :entrainement, user: coach1, start_at: 2.months.ago)
      
      stats = described_class.new
      coaches = stats.active_coaches
      
      expect(coaches.first).to eq(coach1)
      expect(coaches.last).to eq(coach2)
    end
  end

  describe '#monthly_stats_for_current_year' do
    let(:current_time) { Time.zone.local(2024, 6, 15) }

    before do
      travel_to(current_time)
    end

    after do
      travel_back
    end

    it 'returns monthly stats for current year' do
      create(:session, :entrainement, user: coach1, start_at: Time.zone.local(2024, 1, 15))
      create(:session, :entrainement, user: coach1, start_at: Time.zone.local(2024, 2, 15))
      create(:session, :entrainement, user: coach2, start_at: Time.zone.local(2024, 2, 20))
      
      stats = described_class.new
      monthly_stats = stats.monthly_stats_for_current_year
      
      expect(monthly_stats.length).to be > 0
      expect(monthly_stats.first[:year]).to eq(2024)
    end

    it 'includes coach breakdown for each month' do
      create(:session, :entrainement, user: coach1, start_at: Time.zone.local(2024, 1, 15))
      
      stats = described_class.new
      monthly_stats = stats.monthly_stats_for_current_year
      
      january = monthly_stats.find { |s| s[:month] == 1 }
      expect(january).to be_present
      expect(january[:by_coach]).to be_present
    end

    it 'calculates total sessions and amount per month' do
      create(:session, :entrainement, user: coach1, start_at: Time.zone.local(2024, 1, 15))
      create(:session, :entrainement, user: coach1, start_at: Time.zone.local(2024, 1, 20))
      
      stats = described_class.new
      monthly_stats = stats.monthly_stats_for_current_year
      
      january = monthly_stats.find { |s| s[:month] == 1 }
      expect(january[:total_sessions]).to eq(2)
      expect(january[:total_amount]).to eq(100.0) # 2 sessions * 50 euros
    end

    it 'returns stats in reverse order (most recent first)' do
      create(:session, :entrainement, user: coach1, start_at: Time.zone.local(2024, 1, 15))
      create(:session, :entrainement, user: coach1, start_at: Time.zone.local(2024, 6, 15))
      
      stats = described_class.new
      monthly_stats = stats.monthly_stats_for_current_year
      
      expect(monthly_stats.first[:month]).to be >= monthly_stats.last[:month]
    end

    it 'only includes months up to current month' do
      travel_to(Time.zone.local(2024, 3, 15)) do
        stats = described_class.new
        monthly_stats = stats.monthly_stats_for_current_year
        
        expect(monthly_stats.map { |s| s[:month] }).not_to include(4, 5, 6)
      end
    end
  end

  describe '#yearly_stats' do
    it 'returns yearly stats for all years with sessions' do
      create(:session, :entrainement, user: coach1, start_at: Time.zone.local(2022, 6, 15))
      create(:session, :entrainement, user: coach1, start_at: Time.zone.local(2023, 6, 15))
      create(:session, :entrainement, user: coach1, start_at: Time.zone.local(2024, 6, 15))
      
      stats = described_class.new
      yearly_stats = stats.yearly_stats
      
      expect(yearly_stats.length).to eq(3)
      expect(yearly_stats.map { |s| s[:year] }).to include(2022, 2023, 2024)
    end

    it 'returns empty array when no sessions exist' do
      stats = described_class.new
      yearly_stats = stats.yearly_stats
      
      expect(yearly_stats).to eq([])
    end

    it 'includes coach breakdown for each year' do
      create(:session, :entrainement, user: coach1, start_at: Time.zone.local(2024, 1, 15))
      create(:session, :entrainement, user: coach2, start_at: Time.zone.local(2024, 6, 15))
      
      stats = described_class.new
      yearly_stats = stats.yearly_stats
      
      year_2024 = yearly_stats.find { |s| s[:year] == 2024 }
      expect(year_2024[:by_coach]).to be_present
      expect(year_2024[:by_coach].keys).to include(coach1.id, coach2.id)
    end

    it 'calculates total sessions and amount per year' do
      create(:session, :entrainement, user: coach1, start_at: Time.zone.local(2024, 1, 15))
      create(:session, :entrainement, user: coach1, start_at: Time.zone.local(2024, 6, 15))
      
      stats = described_class.new
      yearly_stats = stats.yearly_stats
      
      year_2024 = yearly_stats.find { |s| s[:year] == 2024 }
      expect(year_2024[:total_sessions]).to eq(2)
      expect(year_2024[:total_amount]).to eq(100.0)
    end

    it 'returns stats in reverse order (most recent first)' do
      create(:session, :entrainement, user: coach1, start_at: Time.zone.local(2022, 6, 15))
      create(:session, :entrainement, user: coach1, start_at: Time.zone.local(2024, 6, 15))
      
      stats = described_class.new
      yearly_stats = stats.yearly_stats
      
      expect(yearly_stats.first[:year]).to be >= yearly_stats.last[:year]
    end
  end

  describe 'with custom time zone' do
    it 'uses the specified time zone' do
      stats = described_class.new(time_zone: 'America/New_York')
      
      expect(stats.instance_variable_get(:@time_zone)).to eq('America/New_York')
    end
  end
end

