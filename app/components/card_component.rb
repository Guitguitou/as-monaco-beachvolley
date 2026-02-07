# frozen_string_literal: true

class CardComponent < ViewComponent::Base
  attr_reader :variant, :padding, :options

  def initialize(variant: :flat, padding: :md, **options)
    @variant = variant
    @padding = padding
    @options = options
  end

  def classes
    base = "bg-white"
    "#{base} #{variant_classes} #{padding_classes} #{options[:class]}"
  end

  private

  def variant_classes
    case variant
    when :flat
      ""
    when :default
      "shadow-sm"
    when :elevated
      "shadow-md"
    else
      "shadow-sm"
    end
  end

  def padding_classes
    case padding
    when :none
      "p-0"
    when :sm
      "p-4"
    when :md
      "p-6"
    when :lg
      "p-8"
    else
      "p-6"
    end
  end
end

