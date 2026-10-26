# frozen_string_literal: true

module DataTable
  module Filters
    # Bornes « de » / « à » incluses, l'une ou l'autre facultative. La valeur
    # saisie est un Hash { "from" => …, "to" => … }.
    class Range < Base
      def normalize(value)
        value = value.to_unsafe_h if value.respond_to?(:to_unsafe_h)
        return {} unless value.is_a?(Hash)

        { from: parse(value["from"]), to: parse(value["to"]) }.compact
      end

      private

      def where(relation, bounds)
        relation = relation.where(arel.gteq(lower(bounds[:from]))) if bounds[:from]
        relation = relation.where(arel.lteq(upper(bounds[:to]))) if bounds[:to]
        relation
      end

      def lower(value) = value
      def upper(value) = value
    end
  end
end
