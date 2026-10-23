# frozen_string_literal: true

module Sessions
  # État de navigation de la liste des sessions (vue, semaine, filtres) à
  # conserver quand on revient d'une session vers la liste. Le terrain est
  # ramené à son id, même venu d'un ancien lien (`?terrain=Terrain 1`).
  module ReturnParams
    VIEWS = %w[grid calendar].freeze

    def self.from(params)
      {
        view: params[:view].presence_in(VIEWS),
        date: params[:date].presence,
        for_me: ActiveModel::Type::Boolean.new.cast(params[:for_me]) ? "1" : nil,
        terrain: Terrain.resolve(params[:terrain])&.id
      }.compact
    end
  end
end
