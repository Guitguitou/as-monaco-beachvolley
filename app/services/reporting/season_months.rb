# frozen_string_literal: true

module Reporting
  # Les mois d'une saison à afficher (jusqu'au mois en cours pour la saison
  # en cours) et le regroupement par mois d'une requête, dans le fuseau du club.
  class SeasonMonths
    attr_reader :season

    def initialize(season, today: Date.current)
      @season = season
      @today = today
    end

    def months = season.months.select { |month| month <= @today }

    def label(month) = I18n.l(month, format: "%b %y")

    # Date de fin de la période comparable : aujourd'hui pour la saison en
    # cours, la fin de saison sinon.
    def until_date = season.cover?(@today) ? @today : season.ends_on

    def range = season.starts_on.in_time_zone.beginning_of_day..until_date.in_time_zone.end_of_day

    # La même durée écoulée, une saison plus tôt : comparer à date égale.
    def previous
      self.class.new(season.previous, today: season.cover?(@today) ? @today.prev_year : season.previous.ends_on)
    end

    # { [groupe, premier jour du mois] => valeur } pour `relation`.
    def group(relation, time_column, by: nil, &aggregate)
      month = Arel.sql("DATE_TRUNC('month', #{time_column} AT TIME ZONE 'UTC' AT TIME ZONE '#{Time.zone.tzinfo.name}')")
      grouped = relation.group(*[ by, month ].compact)
      result = aggregate ? aggregate.call(grouped) : grouped.count
      result.transform_keys { |key| key.is_a?(Array) ? [ *key[0...-1], key.last.to_date ] : [ key.to_date ] }
    end

    # Une série Chartkick { libellé du mois => valeur } couvrant tous les mois.
    def series(values_by_month)
      months.to_h { |month| [ label(month), values_by_month.fetch(month, 0) ] }
    end

    # La série d'un groupe dans un résultat de `group(..., by:)`.
    def series_for(grouped, key, &convert)
      convert ||= :itself.to_proc
      series(grouped.filter_map { |(group, month), value| [ month, convert.call(value) ] if group == key }.to_h)
    end
  end
end
