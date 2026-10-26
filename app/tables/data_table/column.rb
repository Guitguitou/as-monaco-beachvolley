# frozen_string_literal: true

module DataTable
  # Une colonne d'un tableau de données : son libellé, son tri (expression
  # SQL), son filtre et sa valeur dans l'export CSV.
  #
  #   Column.new(key: :email, label: "Email", sort: "users.email",
  #              filter: Filters::Text.new("users.email"), csv: :email.to_proc)
  class Column < Data.define(:key, :label, :sort, :filter, :csv, :class_name)
    def initialize(key:, label:, sort: nil, filter: nil, csv: nil, class_name: nil) = super

    def sortable? = sort.present?
  end
end
