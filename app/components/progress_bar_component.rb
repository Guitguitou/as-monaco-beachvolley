# frozen_string_literal: true

class ProgressBarComponent < ApplicationComponent
  HEIGHTS = { xs: "h-1.5", sm: "h-2", md: "h-2.5" }.freeze
  VARIANTS = {
    training: "bg-blue-600",
    free_play: "bg-green-600",
    private_coaching: "bg-orange-600",
    tournament: "bg-purple-600",
    stage: "bg-yellow-600",
    danger: "bg-red-600"
  }.freeze

  def initialize(value:, max:, variant: :primary, height: :sm)
    @value = value.to_i
    @max = max.to_i
    @variant = variant
    @height = height
  end

  private

  attr_reader :value, :max, :variant, :height

  def percentage
    return 0 if max <= 0

    ((value.to_f / max) * 100).clamp(0, 100)
  end

  def container_classes
    "w-full bg-gray-100 border border-gray-200 rounded-full #{HEIGHTS.fetch(height.to_sym, HEIGHTS[:sm])}"
  end

  def bar_classes
    "h-full rounded-full #{VARIANTS.fetch(variant.to_sym, 'bg-asmbv-red')}"
  end
end
