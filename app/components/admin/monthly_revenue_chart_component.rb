# frozen_string_literal: true

module Admin
  # Évolution mensuelle du CA des packs : histogramme empilé par type de pack
  # et tableau de comparaison de chaque mois avec le précédent.
  #
  #   render Admin::MonthlyRevenueChartComponent.new(
  #     months: Reporting::PacksStats.new.last_months_stats(12),
  #     pack_types: Pack.pack_types.keys
  #   )
  class MonthlyRevenueChartComponent < ApplicationComponent
    # Classes écrites en entier pour que Tailwind les détecte.
    COLORS = {
      "credits" => { fill: "fill-asmbv-red", swatch: "bg-asmbv-red" },
      "licence" => { fill: "fill-asmbv-ocean", swatch: "bg-asmbv-ocean" },
      "stage" => { fill: "fill-amber-500", swatch: "bg-amber-500" },
      "inscription_tournoi" => { fill: "fill-emerald-500", swatch: "bg-emerald-500" },
      "equipements" => { fill: "fill-violet-500", swatch: "bg-violet-500" }
    }.freeze
    DEFAULT_COLOR = { fill: "fill-gray-400", swatch: "bg-gray-400" }.freeze

    def initialize(months:, pack_types:)
      @months = months
      @pack_types = pack_types
    end

    private

    attr_reader :months

    # Seuls les types vendus sur la période ont une couleur et une colonne.
    def types
      @types ||= @pack_types.select { |type| months.any? { |month| amount(month, type).positive? } }
    end

    def empty? = types.empty?

    def chart
      @chart ||= StackedBarChart.new(columns: months.map { |month| amounts(month) }, keys: types)
    end

    def amounts(month) = types.index_with { |type| amount(month, type) }

    def amount(month, type) = month[:by_type].dig(type, :amount) || 0.0

    # Du plus récent au plus ancien, chaque mois accompagné du précédent.
    def comparison_rows
      months.each_with_index.map { |month, index| [ month, index.positive? ? months[index - 1] : nil ] }.reverse
    end

    # [montant, variation en %] pour le total puis chaque type.
    def comparison_cells(month, previous)
      total = [ month[:total], delta(month[:total], previous&.dig(:total)) ]
      by_type = types.map { |type| [ amount(month, type), delta(amount(month, type), previous && amount(previous, type)) ] }
      [ total, *by_type ]
    end

    def current_month = months.last

    def previous_month = months[-2]

    def delta(current, previous)
      return if previous.nil? || previous.zero?

      ((current - previous) / previous * 100).round
    end

    def format_delta(value)
      return "—" if value.nil?

      value.positive? ? "+#{value} %" : "#{value} %"
    end

    def delta_classes(value)
      return "text-gray-400" if value.nil? || value.zero?

      value.positive? ? "text-green-600" : "text-red-600"
    end

    def type_label(type) = t("activerecord.attributes.pack.pack_types.#{type}", default: type.humanize)

    def month_label(month) = l(Date.new(month[:year], month[:month]), format: :month_short)

    def month_title(month) = month[:period]

    def color(type) = COLORS.fetch(type, DEFAULT_COLOR)

    def format_currency(amount) = helpers.number_to_currency(amount, unit: "€", format: "%n %u", precision: 0)
  end
end
