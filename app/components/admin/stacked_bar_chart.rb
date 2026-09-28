# frozen_string_literal: true

module Admin
  # Géométrie d'un histogramme empilé dessiné en SVG côté serveur :
  # échelle verticale arrondie, position des barres et des graduations.
  #
  #   chart = StackedBarChart.new(columns: [ { "a" => 10, "b" => 5 }, { "a" => 3 } ], keys: %w[a b])
  #   chart.segments(0) # => segments empilés de bas en haut
  class StackedBarChart
    WIDTH = 720
    HEIGHT = 260
    MARGIN = { top: 24, right: 8, bottom: 28, left: 64 }.freeze
    BAR_RATIO = 0.6
    TICK_COUNT = 4
    NICE_STEPS = [ 1, 2, 2.5, 5, 10 ].freeze

    Segment = Data.define(:key, :value, :x, :y, :width, :height)
    Tick = Data.define(:value, :y)

    def initialize(columns:, keys:)
      @columns = columns
      @keys = keys
    end

    def width = WIDTH
    def height = HEIGHT
    def left = MARGIN[:left]
    def right = WIDTH - MARGIN[:right]
    def baseline_y = HEIGHT - MARGIN[:bottom]

    def bar_width = slot_width * BAR_RATIO

    def bar_x(index) = left + (index * slot_width) + ((slot_width - bar_width) / 2)

    def center_x(index) = bar_x(index) + (bar_width / 2)

    def total_y(index) = y_for(total(index))

    def segments(index)
      bottom = baseline_y
      @keys.filter_map do |key|
        value = @columns[index].fetch(key, 0)
        next if value.zero?

        segment_height = baseline_y - y_for(value)
        bottom -= segment_height
        Segment.new(key:, value:, x: bar_x(index), y: bottom, width: bar_width, height: segment_height)
      end
    end

    def ticks
      (0..TICK_COUNT).map { |i| Tick.new(value: tick_step * i, y: y_for(tick_step * i)) }
    end

    private

    def total(index) = @columns[index].values_at(*@keys).compact.sum

    def slot_width = (right - left).to_f / @columns.size

    def plot_height = baseline_y - MARGIN[:top]

    def y_for(value) = baseline_y - (value / scale_max.to_f * plot_height)

    def scale_max = tick_step * TICK_COUNT

    def tick_step
      @tick_step ||= begin
        raw = @columns.each_index.map { |i| total(i) }.max.to_f / TICK_COUNT
        raw.positive? ? nice(raw) : 25
      end
    end

    def nice(value)
      magnitude = 10**Math.log10(value).floor
      NICE_STEPS.map { |step| step * magnitude }.find { |candidate| candidate >= value }
    end
  end
end
