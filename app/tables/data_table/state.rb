# frozen_string_literal: true

module DataTable
  # Recherche, filtres, filtre rapide, tri et page lus dans l'URL : l'état
  # d'un tableau se partage par simple lien.
  #
  #   ?q=dupont&f[license_type]=libre&quick=cannot_book&sort=name&direction=desc&page=2
  class State
    PARAMS = %i[q quick sort direction page].freeze

    attr_reader :query, :quick, :sort, :page

    def initialize(params)
      @params = params
      @query = params[:q].to_s.strip.presence
      @quick = params[:quick].presence
      @sort = params[:sort].presence
      @direction = params[:direction] == "desc" ? "desc" : "asc"
      @page = params[:page]
    end

    def direction = @direction.to_sym

    def filters
      raw = @params[:f]
      raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : {}
    end

    def filter(key) = filters[key.to_s]

    def sorted_by?(key) = sort == key.to_s

    def filtered? = query.present? || quick.present? || filters.values.any?(&:present?)

    # Paramètres de l'URL courante, modifiés par `changes` (nil retire la clé).
    # Changer de filtre ou de tri revient à la première page.
    def to_params(**changes)
      current = { q: query, quick: quick, sort: sort, direction: (@direction if sort), f: filters.presence }
      current.merge(page: nil).merge(changes).compact_blank
    end

    def sort_params(key)
      next_direction = sorted_by?(key) && @direction == "asc" ? "desc" : "asc"
      to_params(sort: key.to_s, direction: next_direction)
    end
  end
end
