# frozen_string_literal: true

module DataTable
  module Filters
    # Plage de dates ; sur une colonne horaire, les jours bornes sont inclus en entier.
    class DateRange < Range
      private

      def parse(value)
        Date.iso8601(value.to_s) if value.present?
      rescue Date::Error
        nil
      end

      def lower(date) = date.in_time_zone.beginning_of_day
      def upper(date) = date.in_time_zone.end_of_day
    end
  end
end
