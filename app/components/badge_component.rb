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
      "bg-white border-gray-300 text-gray-900"
    when :warning
      "bg-amber-100 border-amber-300 text-amber-900"
    when :danger
      "bg-gray-900 border-gray-900 text-white"
    when :info
      "bg-white border-gray-300 text-gray-900"
    when :purple
      "bg-gray-900 border-gray-900 text-white"
    when :type_training
      "bg-white border-gray-300 text-gray-900"
    when :type_free_play
      "bg-white border-gray-300 text-gray-900"
    when :type_private
      "bg-gray-900 border-gray-900 text-white"
    when :type_tournament
      "bg-gray-900 border-gray-900 text-white"
    when :type_stage
      "bg-amber-100 border-amber-300 text-amber-900"
    else
      "bg-white border-gray-300 text-gray-900"
    end
  end
end

