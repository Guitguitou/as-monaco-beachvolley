# frozen_string_literal: true

module DataTable
  module Filters
    # Une valeur parmi une liste, ou plusieurs (`multiple: true`).
    # `options` : paires [libellé, valeur].
    class Select < Base
      attr_reader :options

      def initialize(sql = nil, options:, multiple: false, scope: nil)
        super(sql, scope: scope)
        @options = options
        @multiple = multiple
      end

      def multiple? = @multiple

      def active?(value) = Array(value).compact_blank.any?

      def normalize(value) = @multiple ? Array(value).compact_blank : value

      private

      def where(relation, value) = relation.where(sql => value)
    end
  end
end
