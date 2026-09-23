# frozen_string_literal: true

class BadgeComponent < ApplicationComponent
  SIZES = {
    xs: "px-2 py-1 text-[10px]",
    sm: "px-2.5 py-1 text-[10px]",
    md: "px-3 py-1.5 text-xs"
  }.freeze

  VARIANTS = {
    success: "bg-green-600 border-green-700 text-white",
    warning: "bg-orange-600 border-orange-700 text-white",
    danger: "bg-red-600 border-red-700 text-white",
    destructive: "bg-red-600 border-red-700 text-white",
    info: "bg-blue-700 border-blue-800 text-white",
    purple: "bg-gray-900 border-gray-900 text-white",
    type_training: "bg-asmbv-red border-asmbv-red-dark text-white",
    type_free_play: "bg-blue-700 border-blue-800 text-white",
    type_private: "bg-gray-900 border-gray-900 text-white",
    type_tournament: "bg-amber-500 border-amber-600 text-gray-900",
    type_stage: "bg-orange-600 border-orange-700 text-white",
    hero: "bg-white/10 border-white text-white",
    hero_inverse: "bg-white border-white text-asmbv-red"
  }.freeze

  def initialize(label:, variant: :neutral, size: :sm, icon: nil)
    @label = label
    @variant = variant
    @size = size
    @icon = icon
  end

  private

  attr_reader :label, :variant, :size, :icon

  def classes
    [
      "inline-flex items-center gap-1 border uppercase tracking-wide font-bold leading-none select-none rounded-full",
      SIZES.fetch(size.to_sym, SIZES[:sm]),
      VARIANTS.fetch(variant.to_sym, "bg-white border-gray-300 text-gray-900")
    ].join(" ")
  end
end
