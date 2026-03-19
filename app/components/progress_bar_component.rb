# frozen_string_literal: true

class ProgressBarComponent < ViewComponent::Base
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
    [
      "w-full",
      "bg-gray-100",
      "border border-gray-200",
      "rounded-none",
      height_classes
    ].join(" ")
  end

  def bar_classes
    [
      "h-full",
      "rounded-none",
      variant_classes
    ].join(" ")
  end

  def height_classes
    case height.to_sym
    when :xs then "h-1.5"
    when :sm then "h-2"
    when :md then "h-2.5"
    else "h-2"
    end
  end

  def variant_classes
    case variant.to_sym
    when :training then "bg-blue-600"
    when :free_play then "bg-green-600"
    when :private_coaching then "bg-orange-600"
    when :tournament then "bg-purple-600"
    when :stage then "bg-yellow-600"
    when :danger then "bg-red-600"
    else "bg-asmbv-red"
    end
  end
end

