# frozen_string_literal: true

module Admin
  # Période affichée dans l'onglet Sessions du dashboard (semaine, mois ou
  # année), à partir de l'ancre passée dans l'URL, et ses voisines pour la
  # navigation précédent / suivant.
  class SessionsPeriod
    TIMEZONE = "Europe/Paris"

    Unit = Data.define(:step, :anchor_format, :anchor_suffix, :bounds, :label)

    UNITS = {
      "week" => Unit.new(
        step: 1.week, anchor_format: "%Y-%m-%d", anchor_suffix: "",
        bounds: ->(time) { [ time.beginning_of_week(:monday), time.end_of_week(:monday) ] },
        label: ->(start) { "#{I18n.l(start, format: :short)} – #{I18n.l(start.end_of_week(:monday), format: :short)}" }
      ),
      "month" => Unit.new(
        step: 1.month, anchor_format: "%Y-%m", anchor_suffix: "-01",
        bounds: ->(time) { [ time.beginning_of_month, time.end_of_month ] },
        label: ->(start) { I18n.l(start, format: :month_and_year) }
      ),
      "year" => Unit.new(
        step: 1.year, anchor_format: "%Y", anchor_suffix: "-01-01",
        bounds: ->(time) { [ time.beginning_of_year, time.end_of_year ] },
        label: ->(start) { start.year.to_s }
      )
    }.freeze

    attr_reader :name, :range

    def initialize(name, anchor, now: Time.current)
      @name = UNITS.key?(name) ? name : "week"
      @unit = UNITS.fetch(@name)
      time = anchor.present? ? Time.zone.parse("#{anchor}#{@unit.anchor_suffix}") : now
      @range = Range.new(*@unit.bounds.call(time.in_time_zone(TIMEZONE)))
    end

    def label
      @unit.label.call(range.first)
    end

    def previous_anchor
      (range.first - @unit.step).strftime(@unit.anchor_format)
    end

    def next_anchor
      (range.first + @unit.step).strftime(@unit.anchor_format)
    end
  end
end
