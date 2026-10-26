# frozen_string_literal: true

module Admin
  # Choix de la saison d'un dashboard analytique : saison précédente /
  # suivante, sans aller au-delà de la saison en cours.
  class SeasonSelectorComponent < ApplicationComponent
    PARAM = :saison

    # Saison demandée dans l'URL (?saison=2025), la saison en cours sinon.
    def self.season_from(params, current: Season.current)
      year = params[PARAM].to_s
      return current unless year.match?(/\A\d{4}\z/) && year.to_i <= current.starts_on.year

      current.with(starts_on: current.starts_on.change(year: year.to_i))
    end

    def initialize(season:, tab:, current: Season.current)
      @season = season
      @tab = tab
      @current = current
    end

    private

    attr_reader :season

    def url(target) = helpers.admin_root_path(tab: @tab, PARAM => target.starts_on.year)

    def next_season = season.with(starts_on: season.starts_on.next_year)

    def next? = season.starts_on < @current.starts_on

    def current? = season == @current
  end
end
