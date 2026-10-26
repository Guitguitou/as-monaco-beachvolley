# frozen_string_literal: true

module DataTable
  module Filters
    # Oui / Non ; vide : sans filtre.
    class Boolean < Base
      OPTIONS = [ [ "Oui", "1" ], [ "Non", "0" ] ].freeze

      def options = OPTIONS

      def normalize(value) = value.presence && ActiveModel::Type::Boolean.new.cast(value)

      def active?(value) = !value.nil?

      private

      def where(relation, value) = relation.where(sql => value)
    end
  end
end
