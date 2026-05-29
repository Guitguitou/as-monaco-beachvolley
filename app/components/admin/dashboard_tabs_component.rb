# frozen_string_literal: true

module Admin
  class DashboardTabsComponent < ApplicationComponent
    def initialize(active_tab: "overview")
      @active_tab = active_tab
    end

    private

    attr_reader :active_tab

    def tabs
      [
        { id: "overview", name: "Vue d'ensemble", icon: "📊" },
        { id: "sessions", name: "Sessions", icon: "🏐" },
        { id: "finances", name: "Finances", icon: "💰" },
        { id: "packs", name: "Packs", icon: "📦" },
        { id: "coaches", name: "Coachs", icon: "👥" },
        { id: "alerts", name: "Alertes", icon: "⚠️" }
      ]
    end

    def tab_classes(tab_id)
      base_classes = "px-4 py-2 text-sm font-medium rounded-md transition-colors duration-200"

      if tab_id == active_tab
        "#{base_classes} bg-asmbv-red text-white"
      else
        "#{base_classes} text-gray-500 hover:text-gray-700 hover:bg-gray-100"
      end
    end
  end
end
