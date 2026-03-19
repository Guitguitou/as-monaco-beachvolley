# frozen_string_literal: true

class CardComponent < ViewComponent::Base
  renders_one :header
  renders_one :footer

  def initialize(href: nil, accent: nil, padding: :md, class_name: nil)
    @href = href
    @accent = accent
    @padding = padding
    @class_name = class_name
  end

  private

  attr_reader :href, :accent, :padding, :class_name

  def tag_name
    href.present? ? :a : :div
  end

  def tag_options
    opts = { class: classes }
    opts[:href] = href if href.present?
    opts
  end

  def classes
    [
      "block",
      "border border-gray-200",
      "rounded-none",
      "bg-white",
      "shadow-sm",
      "transition-shadow duration-150",
      "hover:shadow-md",
      padding_classes,
      accent_border_classes,
      class_name
    ].compact.join(" ")
  end

  def padding_classes
    case padding.to_sym
    when :none
      ""
    when :sm
      "p-4"
    when :md
      "p-5"
    when :lg
      "p-6"
    else
      "p-5"
    end
  end

  def accent_border_classes
    return nil if accent.blank?

    case accent.to_sym
    when :training
      "border-t-4 border-t-asmbv-red"
    when :free_play
      "border-t-4 border-t-blue-700"
    when :private_coaching
      "border-t-4 border-t-gray-900"
    when :tournament
      "border-t-4 border-t-amber-500"
    when :stage
      "border-t-4 border-t-orange-600"
    else
      nil
    end
  end
end

