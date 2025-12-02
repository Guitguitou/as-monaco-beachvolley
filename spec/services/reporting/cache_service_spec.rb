# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reporting::CacheService do
  describe '.cache_key' do
    it 'generates a cache key with service name and method' do
      key = described_class.cache_key('KPIs', 'total_revenue', 2024)
      expect(key).to include('reporting_KPIs_total_revenue_2024')
      expect(key).to include(Date.current.strftime('%Y%m%d'))
    end

    it 'handles multiple arguments' do
      key = described_class.cache_key('KPIs', 'revenue_by_month', 2024, 'January')
      expect(key).to include('reporting_KPIs_revenue_by_month_2024_January')
    end

    it 'includes current date in the key' do
      key1 = described_class.cache_key('KPIs', 'test')
      key2 = described_class.cache_key('KPIs', 'test')
      expect(key1).to eq(key2)
    end
  end

  describe '.fetch' do
    around do |example|
      # Temporarily enable memory cache for these tests
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      example.run
      Rails.cache = original_cache
    end

    before do
      Rails.cache.clear
    end

    after do
      Rails.cache.clear
    end

    it 'caches the result of the block' do
      freeze_time do
        call_count = 0
        
        # First call should execute the block
        result1 = described_class.fetch('CacheTestService', 'unique_method_name') do
          call_count += 1
          'cached_result'
        end
        
        # Second call should use cached value
        result2 = described_class.fetch('CacheTestService', 'unique_method_name') do
          call_count += 1
          'should_not_be_called'
        end
        
        expect(result1).to eq('cached_result')
        expect(result2).to eq('cached_result')
        expect(call_count).to eq(1)
      end
    end

    it 'expires cache after duration' do
      described_class.fetch('TestService', 'test_method') do
        'cached'
      end
      
      travel(Reporting::CacheService::CACHE_DURATION + 1.second) do
        call_count = 0
        described_class.fetch('TestService', 'test_method') do
          call_count += 1
          'new_result'
        end
        
        expect(call_count).to eq(1)
      end
    end

    it 'uses different keys for different arguments' do
      result1 = described_class.fetch('TestService', 'method', 'arg1') { 'result1' }
      result2 = described_class.fetch('TestService', 'method', 'arg2') { 'result2' }
      
      expect(result1).to eq('result1')
      expect(result2).to eq('result2')
    end
  end

  describe '.clear_all' do
    before do
      Rails.cache.clear
    end

    it 'clears all reporting cache entries' do
      described_class.fetch('Service1', 'method1') { 'value1' }
      described_class.fetch('Service2', 'method2') { 'value2' }
      
      described_class.clear_all
      
      call_count = 0
      described_class.fetch('Service1', 'method1') do
        call_count += 1
        'new_value'
      end
      
      expect(call_count).to eq(1)
    end
  end

  describe '.clear_for_date' do
    before do
      Rails.cache.clear
    end

    it 'clears cache entries for a specific date' do
      today = Date.current
      yesterday = today - 1.day
      
      described_class.fetch('Service', 'method') { 'today_value' }
      
      travel_to(yesterday) do
        described_class.fetch('Service', 'method') { 'yesterday_value' }
      end
      
      described_class.clear_for_date(today)
      
      # Today's cache should be cleared
      call_count = 0
      described_class.fetch('Service', 'method') do
        call_count += 1
        'new_value'
      end
      
      expect(call_count).to eq(1)
    end
  end
end

