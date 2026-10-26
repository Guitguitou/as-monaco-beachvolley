# frozen_string_literal: true

module DataTable
  # Applique l'état d'un tableau (recherche, filtres, filtre rapide, tri) à une
  # relation, selon la définition du tableau.
  class Query
    def self.call(relation:, definition:, state:) = new(definition, state).apply(relation)

    def initialize(definition, state)
      @definition = definition
      @state = state
    end

    def apply(relation)
      relation = search(relation)
      relation = filter(relation)
      relation = @definition.quick_filter(@state.quick)&.apply(relation) || relation
      sort(relation)
    end

    private

    def search(relation)
      return relation unless @state.query && @definition.searchable?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@state.query)}%"
      conditions = @definition.search_columns.map { |sql| Arel::Nodes::SqlLiteral.new(sql).matches(pattern) }
      relation.where(conditions.reduce(:or))
    end

    def filter(relation)
      @definition.columns.select(&:filter).reduce(relation) do |scope, column|
        column.filter.apply(scope, @state.filter(column.key))
      end
    end

    def sort(relation)
      column = @definition.column(@state.sort)
      return relation.reorder(@definition.default_order) unless column&.sortable?

      relation.reorder(Array(column.sort).map { |sql| Arel.sql("#{sql} #{@state.direction}") })
    end
  end
end
