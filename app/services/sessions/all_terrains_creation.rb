# frozen_string_literal: true

module Sessions
  # Crée la même session sur chacun des terrains, ou aucune si l'un d'eux
  # refuse. Le bloc reçoit chaque session créée, dans la transaction.
  class AllTerrainsCreation
    def initialize(attributes, terrains: Terrain.active.ordered)
      @attributes = attributes.except("terrain", :terrain, "terrain_id", :terrain_id)
      @terrains = terrains
    end

    # Renvoie les erreurs de la session refusée, vide si tout est créé.
    def call
      errors = []
      ActiveRecord::Base.transaction do
        @terrains.each do |terrain|
          session = Session.new(@attributes.merge("terrain" => terrain))
          unless session.save
            errors << session.errors.full_messages.to_sentence
            raise ActiveRecord::Rollback
          end
          yield session
        end
      end
      errors
    end
  end
end
