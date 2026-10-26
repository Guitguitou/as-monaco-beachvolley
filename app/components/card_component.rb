# frozen_string_literal: true

# Carte blanche de l'app.
#
#   render CardComponent.new(padding: :lg) { ... }
#   render CardComponent.new(title: "Sessions à venir", icon: "calendar", padding: :none) do |card|
#     card.with_title_aside { render BadgeComponent.new(label: "3") }
#     ...
#   end
#
# `title` rend la barre d'en-tête (titre, icône, sous-titre, élément à droite)
# qui était recopiée dans le dashboard et les finances ; le `padding` ne
# s'applique alors qu'au corps, sous la barre.
class CardComponent < ApplicationComponent
  renders_one :header
  renders_one :footer
  renders_one :title_aside

  PADDINGS = { none: "", sm: "p-4", md: "p-5", lg: "p-6" }.freeze
  ACCENTS = {
    training: "border-t-4 border-t-brand",
    free_play: "border-t-4 border-t-blue-700",
    private_coaching: "border-t-4 border-t-gray-900",
    tournament: "border-t-4 border-t-amber-500",
    stage: "border-t-4 border-t-orange-600",
    cold: "border-t-4 border-t-sky-400"
  }.freeze

  def initialize(href: nil, accent: nil, padding: :md, class_name: nil, title: nil, subtitle: nil, icon: nil)
    @href = href
    @accent = accent
    @padding = padding
    @class_name = class_name
    @title = title
    @subtitle = subtitle
    @icon = icon
  end

  private

  attr_reader :href, :accent, :padding, :class_name, :title, :subtitle, :icon

  def padding_classes
    PADDINGS.fetch(padding.to_sym, PADDINGS[:md])
  end

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
      ("block" if href.present?),
      "border border-gray-200",
      "rounded-none",
      "bg-white",
      "shadow-sm",
      "transition-shadow duration-150",
      "hover:shadow-md",
      (padding_classes unless title),
      ACCENTS[accent&.to_sym],
      class_name
    ].compact.join(" ")
  end
end
