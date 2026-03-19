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
      "transition",
      "hover:shadow-sm",
      "hover:border-gray-300",
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
      "border-t-4 border-t-blue-500"
    when :free_play
      "border-t-4 border-t-green-500"
    when :private_coaching
      "border-t-4 border-t-orange-500"
    when :tournament
      "border-t-4 border-t-purple-500"
    when :stage
      "border-t-4 border-t-yellow-500"
    else
      nil
    end
  end
end

