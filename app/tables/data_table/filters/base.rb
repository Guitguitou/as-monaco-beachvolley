# frozen_string_literal: true

module DataTable
  module Filters
    # Un filtre de colonne : `apply` reçoit la relation et la valeur saisie,
    # la normalise (`normalize`) et ne filtre que si elle est renseignée
    # (`active?`) ; sans `scope:` explicite, il filtre sur `sql`.
    class Base
      attr_reader :sql

      def initialize(sql = nil, scope: nil)
        @sql = sql
        @scope = scope
      end

      def apply(relation, raw)
        value = normalize(raw)
        return relation unless active?(value)

        @scope ? @scope.call(relation, value) : where(relation, value)
      end

      def normalize(value) = value

      def active?(value) = value.present?

      def type = self.class.name.demodulize.underscore.to_sym

      private

      def arel = Arel::Nodes::SqlLiteral.new(sql)
    end
  end
end
