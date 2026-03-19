# frozen_string_literal: true

class BadgeComponent < ViewComponent::Base
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
      "inline-flex items-center gap-1",
      "border",
      "uppercase tracking-wide",
      "font-bold",
      "leading-none",
      "select-none",
      radius_classes,
      size_classes,
      variant_classes
    ].join(" ")
  end

  def radius_classes
    "rounded-none"
  end

  def size_classes
    case size.to_sym
    when :xs
      "px-2 py-1 text-[10px]"
    when :sm
      "px-2.5 py-1 text-[10px]"
    when :md
      "px-3 py-1.5 text-xs"
    else
      "px-2.5 py-1 text-[10px]"
    end
  end

  def variant_classes
    case variant.to_sym
    when :success
      "bg-green-600 border-green-700 text-white"
    when :warning
      "bg-orange-600 border-orange-700 text-white"
    when :danger, :destructive
      "bg-red-600 border-red-700 text-white"
    when :info
      "bg-blue-700 border-blue-800 text-white"
    when :purple
      "bg-gray-900 border-gray-900 text-white"
    when :type_training
      "bg-asmbv-red border-asmbv-red-dark text-white"
    when :type_free_play
      "bg-blue-700 border-blue-800 text-white"
    when :type_private
      "bg-gray-900 border-gray-900 text-white"
    when :type_tournament
      "bg-amber-500 border-amber-600 text-gray-900"
    when :type_stage
      "bg-orange-600 border-orange-700 text-white"
    when :hero
      "bg-white/10 border-white text-white"
    when :hero_inverse
      "bg-white border-white text-asmbv-red"
    else
      "bg-white border-gray-300 text-gray-900"
    end
  end
end

