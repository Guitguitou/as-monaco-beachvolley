# frozen_string_literal: true

module DataTable
  module Filters
    # Contient le texte saisi, sans tenir compte de la casse.
    class Text < Base
      private

      def where(relation, value)
        relation.where(arel.matches("%#{ActiveRecord::Base.sanitize_sql_like(value.to_s.strip)}%"))
      end
    end
  end
end
