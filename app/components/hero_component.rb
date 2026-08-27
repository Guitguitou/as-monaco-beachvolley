# frozen_string_literal: true

class HeroComponent < ApplicationComponent
  renders_one :top
  renders_one :eyebrow
  renders_one :meta
  renders_one :actions

  def initialize(title:, subtitle: nil, variant: :red, flush_title: false, title_font: :bebas)
    @title = title
    @subtitle = subtitle
    @variant = variant
    @flush_title = flush_title
    @title_font = title_font
  end

  private

  attr_reader :title, :subtitle, :variant, :flush_title, :title_font

  def wrapper_classes
    case variant.to_sym
    when :red
      "bg-asmbv-red bg-gradient-to-r from-asmbv-red to-asmbv-red-dark"
    when :dark
      "bg-gray-900"
    when :white
      "bg-white border-b border-gray-200"
    else
      "bg-gray-900"
    end
  end

  def title_classes
    font_class = title_font.to_sym == :anton ? "font-anton" : "font-bebas-neue"
    text_color = variant.to_sym == :white ? "text-gray-900" : "text-white"
    base = "text-3xl sm:text-4xl lg:text-5xl #{font_class} tracking-tight leading-tight #{text_color}"
    flush_title ? base : "mt-3 #{base}"
  end

  def subtitle_classes
    text_color = variant.to_sym == :white ? "text-gray-600" : "text-white"
    "mt-2 text-sm #{text_color}"
  end
end
