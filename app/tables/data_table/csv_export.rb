# frozen_string_literal: true

require "csv"

module DataTable
  # Export CSV des lignes filtrées d'un tableau : les colonnes qui déclarent
  # une valeur `csv`, dans leur ordre d'affichage.
  class CsvExport
    def initialize(definition:, records:)
      @columns = definition.csv_columns
      @records = records
    end

    def call
      CSV.generate(col_sep: ";") do |csv|
        csv << @columns.map(&:label)
        @records.each { |record| csv << @columns.map { |column| column.csv.call(record).presence } }
      end
    end

    def self.filename(name) = "#{name}-#{Date.current.iso8601}.csv"
  end
end
