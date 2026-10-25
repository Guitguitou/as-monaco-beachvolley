# frozen_string_literal: true

# En-tête de page compact, pour les écrans qui n'ont pas besoin du bandeau rouge
# plein (HeroComponent).
#
# Le HeroComponent coûte ~145 px en desktop et ~200 px en mobile ; quand une page
# n'a rien d'autre à y mettre que son titre, c'est autant d'espace perdu au-dessus
# du pli — et le titre s'y retrouvait dupliqué avec le <h1> de la vue.
#
#   <%= render PageHeaderComponent.new(title: "Calendrier") do |header| %>
#     <% header.with_actions do %>...<% end %>
#   <% end %>
#
# `variant: :admin` rend l'en-tête des index de l'administration : titre en
# gras précédé d'une icône, sans bandeau, actions à droite.
#
#   render PageHeaderComponent.new(title: "Terrains", icon: "map-pin", variant: :admin)
class PageHeaderComponent < ApplicationComponent
  renders_one :actions

  def initialize(title:, subtitle: nil, icon: nil, variant: :default)
    @title = title
    @subtitle = subtitle
    @icon = icon
    @variant = variant
  end

  private

  attr_reader :title, :subtitle, :icon

  def admin?
    @variant == :admin
  end
end
