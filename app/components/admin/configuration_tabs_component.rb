# frozen_string_literal: true

module Admin
  # En-tête de l'écran Configuration : un seul titre et une barre d'onglets
  # (Règles du club, Terrains, Pages publiques, Intégrations), chaque onglet
  # restant une page d'admin à part entière.
  class ConfigurationTabsComponent < ApplicationComponent
    TABS = {
      club_rules: { label: "Règles du club", icon: "sliders-horizontal", path: :admin_club_rules_path },
      terrains: { label: "Terrains", icon: "map-pin", path: :admin_terrains_path },
      public_pages: { label: "Pages publiques", icon: "globe", path: :admin_public_pages_path },
      integrations: { label: "Intégrations", icon: "bot", path: :admin_claude_connections_path }
    }.freeze

    renders_one :actions

    def initialize(active:)
      @active = active
    end

    def self.paths(routes) = TABS.values.map { |tab| routes.public_send(tab[:path]) }

    private

    def tabs
      TABS.map do |key, tab|
        { label: tab[:label], icon: tab[:icon], href: helpers.public_send(tab[:path]), active: key == @active }
      end
    end
  end
end
