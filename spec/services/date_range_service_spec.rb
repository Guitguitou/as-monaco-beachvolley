# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DateRangeService, type: :service do
  describe '.week_range' do
    it 'returns a range for the current week' do
      travel_to(Time.zone.parse('2024-11-07 14:00:00')) # Thursday

      range = DateRangeService.week_range

      expect(range.begin).to eq(Time.zone.parse('2024-11-04 00:00:00')) # Monday
      expect(range.end).to eq(Time.zone.parse('2024-11-10 23:59:59.999999999')) # Sunday

      travel_back
    end
  end

  describe '.month_range' do
    it 'returns a range for the current month' do
      travel_to(Time.zone.parse('2024-11-15 14:00:00'))

      range = DateRangeService.month_range

      expect(range.begin).to eq(Time.zone.parse('2024-11-01 00:00:00'))
      expect(range.end).to eq(Time.zone.parse('2024-11-30 23:59:59.999999999'))

      travel_back
    end
  end

  describe '.year_range' do
    it 'returns a range for the current year' do
      travel_to(Time.zone.parse('2024-06-15 14:00:00'))

      range = DateRangeService.year_range

      expect(range.begin).to eq(Time.zone.parse('2024-01-01 00:00:00'))
      expect(range.end).to eq(Time.zone.parse('2024-12-31 23:59:59.999999999'))

      travel_back
    end
  end
end
