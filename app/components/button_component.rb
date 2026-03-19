# frozen_string_literal: true

class ButtonComponent < ViewComponent::Base
  attr_reader :variant, :size, :options

  def initialize(variant: :primary, size: :medium, shape: :square, icon_only: false, **options)
    @variant = variant
    @size = size
    @shape = shape
    @icon_only = icon_only
    @options = options
  end

  def tag_name
    options[:href] || options[:url] ? :a : :button
  end

  def icon_path
    case options[:icon]
    when :plus
      "M12 4v16m8-8H4"
    when :edit
      "M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
    when :delete
      "M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
    when :save
      "M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4"
    when :cancel
      "M6 18L18 6M6 6l12 12"
    when :arrow_left
      "M10 19l-7-7m0 0l7-7m-7 7h18"
    when :arrow_right
      "M14 5l7 7m0 0l-7 7m7-7H3"
    end
  end

  def classes
    base = "inline-flex items-center justify-center gap-2 font-semibold focus:outline-none focus:ring-2 focus:ring-offset-2 transition-colors duration-150"
    "#{base} #{shape_classes} #{variant_classes} #{size_classes}"
  end

  private

  attr_reader :shape, :icon_only

  def variant_classes
    case variant
    when :primary
      "bg-asmbv-red hover:bg-asmbv-red-dark text-white focus:ring-asmbv-red"
    when :secondary
      "bg-white border border-gray-300 text-gray-800 hover:bg-gray-50 focus:ring-asmbv-red"
    when :ghost
      "bg-white border border-gray-300 text-gray-800 hover:bg-gray-50 focus:ring-asmbv-red"
    when :tertiary
      "bg-transparent text-asmbv-red hover:bg-asmbv-red-light hover:text-asmbv-red-dark focus:ring-asmbv-red"
    when :danger
      "bg-red-600 hover:bg-red-700 text-white focus:ring-red-500"
    when :success
      "bg-green-600 hover:bg-green-700 text-white focus:ring-green-500"
    when :warning
      "bg-yellow-600 hover:bg-yellow-700 text-white focus:ring-yellow-500"
    when :info
      "bg-blue-600 hover:bg-blue-700 text-white focus:ring-blue-500"
    else
      "bg-gray-600 hover:bg-gray-700 text-white focus:ring-gray-500"
    end
  end

  def shape_classes
    case shape
    when :square
      "rounded-none"
    when :slightly_rounded
      "rounded-md"
    else
      "rounded-md"
    end
  end

  def size_classes
    case size
    when :small
      icon_only ? "h-9 w-9 text-sm" : "px-3 py-2 text-sm"
    when :medium
      icon_only ? "h-10 w-10 text-sm" : "px-4 py-2 text-sm"
    when :large
      icon_only ? "h-11 w-11 text-base" : "px-5 py-3 text-base"
    when :xl
      icon_only ? "h-12 w-12 text-lg" : "px-6 py-4 text-lg"
    else
      icon_only ? "h-10 w-10 text-sm" : "px-4 py-2 text-sm"
    end
  end
end
