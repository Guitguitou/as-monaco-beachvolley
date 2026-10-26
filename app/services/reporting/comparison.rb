# frozen_string_literal: true

module Reporting
  # Un chiffre clé et sa valeur sur la période de comparaison (semaine ou
  # saison précédente). `higher_is_better: false` : une hausse est une
  # mauvaise nouvelle (désinscriptions tardives).
  Comparison = Data.define(:key, :label, :icon, :current, :previous, :unit, :higher_is_better) do
    # Sous cette base, un pourcentage d'évolution n'a pas de sens (+5 000 %).
    MIN_BASE = 10

    def initialize(key:, label:, icon:, current:, previous:, unit: nil, higher_is_better: true) = super

    def change = previous.to_f.abs < MIN_BASE ? nil : ((current - previous) / previous.to_f * 100).round

    def trend
      return :flat if current == previous

      (current > previous) == higher_is_better ? :good : :bad
    end
  end
end
