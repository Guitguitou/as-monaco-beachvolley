# frozen_string_literal: true

module Admin
  # Chiffre clé et sa tendance par rapport à la période précédente
  # (semaine, saison) : vert quand c'est une bonne nouvelle, rouge sinon.
  class KpiTileComponent < ApplicationComponent
    TREND_CLASSES = { good: "text-green-700", bad: "text-red-700", flat: "text-gray-500" }.freeze

    def initialize(metric:, previous_label: "la semaine passée")
      @metric = metric
      @previous_label = previous_label
    end

    def call
      render StatTileComponent.new(value: format_value(@metric.current), label: @metric.label, icon: @metric.icon, hint: hint)
    end

    private

    def hint
      tag.span(class: "inline-flex items-center gap-1 #{TREND_CLASSES.fetch(@metric.trend)}") do
        safe_join([ lucide_icon(icon, class: "w-3 h-3", aria: { hidden: true }), trend_text ])
      end
    end

    def icon
      return "minus" if @metric.current == @metric.previous

      @metric.current > @metric.previous ? "trending-up" : "trending-down"
    end

    def trend_text
      change = @metric.change
      prefix = change ? "#{'+' if change.positive?}#{change} % · " : ""
      "#{prefix}#{format_value(@metric.previous)} #{@previous_label}"
    end

    def format_value(value)
      [ helpers.number_with_delimiter(value, delimiter: " "), @metric.unit ].compact.join(" ")
    end
  end
end
