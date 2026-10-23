# frozen_string_literal: true

module Sessions
  # Filtres de la liste des sessions : un terrain, et « pour moi » (les
  # sessions ouvertes aux niveaux du joueur). Le terrain est un id, ou l'ancien
  # nom (« Terrain 1 ») des liens antérieurs ; un terrain inconnu ne montre rien.
  class ListingFilter
    def initialize(terrain:, for_me:, level_ids:)
      @terrain = terrain.presence
      @for_me = for_me
      @level_ids = level_ids
    end

    def apply(scope)
      scope = scope.on_terrain(Terrain.resolve(@terrain)&.id) if @terrain
      scope = scope.for_user_levels(@level_ids) if @for_me
      scope
    end
  end
end
