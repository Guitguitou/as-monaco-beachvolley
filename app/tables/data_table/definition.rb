# frozen_string_literal: true

module DataTable
  # Description d'un tableau : colonnes, recherche, filtres rapides et ordre
  # par défaut. Chaque tableau de l'admin en est une sous-classe, injectée
  # dans DataTable::Query (filtrage), DataTableComponent (affichage) et
  # DataTable::CsvExport (export).
  class Definition
    def columns = raise(NotImplementedError)

    # Colonnes SQL interrogées par la barre de recherche.
    def search_columns = []

    def quick_filters = []

    # Ordre stable quand aucun tri n'est demandé (pagination).
    def default_order = { id: :desc }

    def column(key) = columns.find { |col| col.key.to_s == key.to_s }

    def quick_filter(key) = quick_filters.find { |quick| quick.key.to_s == key.to_s }

    def filterable? = columns.any?(&:filter)

    def searchable? = search_columns.any?

    def csv_columns = columns.select(&:csv)
  end
end
