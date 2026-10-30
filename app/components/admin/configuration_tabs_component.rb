# frozen_string_literal: true

module Admin
  # Écran Configuration : Règles du club, Terrains, Pages publiques, Intégrations.
  class ConfigurationTabsComponent < SectionTabsComponent
    TITLE = "Configuration"
    ICON = "settings"
    TABS = {
      club_rules: { label: "Règles du club", icon: "sliders-horizontal", path: :admin_club_rules_path },
      terrains: { label: "Terrains", icon: "map-pin", path: :admin_terrains_path },
      public_pages: { label: "Pages publiques", icon: "globe", path: :admin_public_pages_path },
      integrations: { label: "Intégrations", icon: "bot", path: :admin_claude_connections_path }
    }.freeze
  end
end
