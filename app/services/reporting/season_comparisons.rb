# frozen_string_literal: true

module Reporting
  # Compare un rapport de saison à celui de la saison précédente, à date
  # égale : chaque chiffre clé est lu sur les deux rapports par le même bloc.
  #
  #   SeasonComparisons.new(report, previous).compare(:revenue, "Encaissé", "euro", unit: "€", &:total_eur)
  class SeasonComparisons
    def initialize(current, previous)
      @current = current
      @previous = previous
    end

    def compare(key, label, icon, **options, &value)
      Comparison.new(key: key, label: label, icon: icon, current: value.call(@current), previous: value.call(@previous), **options)
    end
  end
end
