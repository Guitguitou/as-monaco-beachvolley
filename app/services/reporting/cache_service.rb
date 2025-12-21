# frozen_string_literal: true

module Reporting
  class CacheService
    CACHE_DURATION = 5.minutes

    def self.cache_key(service_name, method_name, *args)
      args_string = args.map(&:to_s).join("_")
      "reporting_#{service_name}_#{method_name}_#{args_string}_#{Date.current.strftime('%Y%m%d')}"
    end

    def self.fetch(service_name, method_name, *args, &block)
      key = cache_key(service_name, method_name, *args)

      Rails.cache.fetch(key, expires_in: CACHE_DURATION) do
        yield
      end
    end

    def self.clear_all
      Rails.cache.delete_matched("reporting_*")
    end

    def self.clear_for_date(date)
      date_str = date.strftime("%Y%m%d")
      Rails.cache.delete_matched("reporting_*_#{date_str}")
    end
  end
end
