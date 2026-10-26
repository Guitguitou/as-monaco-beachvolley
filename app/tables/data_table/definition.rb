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

    private

    # Raccourcis de déclaration des colonnes et des filtres usuels.
    def col(key, label, **options) = Column.new(key: key, label: label, **options)

    def date_col(key, label, sql) = col(key, label, sort: sql, filter: Filters::DateRange.new(sql))

    def select_filter(sql, options) = Filters::Select.new(sql, options: options)

    # Filtre rapide « À venir » : ce qui n'est pas encore terminé.
    def upcoming(label = "À venir", ends_on: :ends_on)
      QuickFilter.new(key: :upcoming, label: label, scope: ->(relation) { relation.where(ends_on => Date.current..) })
    end

    # Filtre rapide sur une période en cours (`:all_week`, `:all_month`) d'une colonne horaire.
    def current_period(key, label, column, period)
      QuickFilter.new(key: key, label: label, scope: ->(relation) { relation.where(column => Time.current.public_send(period)) })
    end

    # Choix multiple de niveaux, via la table de jointure `join` (user_levels, session_levels…).
    def levels_filter(join, foreign_key)
      Filters::Select.new(options: Level.order(:name).map { |level| [ level.display_name, level.id ] }, multiple: true,
                          scope: ->(relation, ids) { relation.where(id: join.where(level_id: ids).select(foreign_key)) })
    end

    def options_from(records, label = :name) = records.map { |record| [ record.public_send(label), record.id ] }
  end
end
