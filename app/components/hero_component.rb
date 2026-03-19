# frozen_string_literal: true

class HeroComponent < ViewComponent::Base
  renders_one :meta
  renders_one :actions

  def initialize(title:, subtitle: nil, variant: :red)
    @title = title
    @subtitle = subtitle
    @variant = variant
  end

  private

  attr_reader :title, :subtitle, :variant

  def wrapper_classes
    case variant.to_sym
    when :red
      "bg-asmbv-red bg-gradient-to-r from-asmbv-red to-asmbv-red-dark"
    else
      "bg-gray-900"
    end
  end

  def title_classes
    "mt-3 text-3xl sm:text-4xl lg:text-5xl font-bebas-neue tracking-tight leading-tight text-white"
  end

  def subtitle_classes
    "mt-2 text-sm text-white/90"
  end
end

