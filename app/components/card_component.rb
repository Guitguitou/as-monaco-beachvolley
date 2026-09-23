# frozen_string_literal: true

class CardComponent < ApplicationComponent
  renders_one :header
  renders_one :footer

  PADDINGS = { none: "", sm: "p-4", md: "p-5", lg: "p-6" }.freeze
  ACCENTS = {
    training: "border-t-4 border-t-asmbv-red",
    free_play: "border-t-4 border-t-blue-700",
    private_coaching: "border-t-4 border-t-gray-900",
    tournament: "border-t-4 border-t-amber-500",
    stage: "border-t-4 border-t-orange-600"
  }.freeze

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
      "rounded-xl",
      "bg-white",
      "shadow-sm",
      "transition-shadow duration-150",
      "hover:shadow-md",
      PADDINGS.fetch(padding.to_sym, PADDINGS[:md]),
      ACCENTS[accent&.to_sym],
      class_name
    ].compact.join(" ")
  end
end
