# frozen_string_literal: true

module Admin
  # Page courante de l'admin, pour savoir quel lien de la barre latérale est
  # actif : une page de détail (/admin/users/3) active son index (/admin/users),
  # et un lien avec query (?tab=alerts) n'est actif que sur cet onglet précis.
  class CurrentLocation
    ROOT = "/admin"

    def initialize(path:, query:)
      @path = path
      @query = query.to_h.stringify_keys
    end

    def active?(item)
      target = URI.parse(item.path)
      return @path == target.path && matches_query?(target.query) if target.path == ROOT

      @path == target.path || @path.start_with?("#{target.path}/")
    end

    private

    def matches_query?(target_query)
      Rack::Utils.parse_query(target_query).all? { |key, value| @query[key] == value } &&
        (target_query.present? || @query["tab"] != "alerts")
    end
  end
end
