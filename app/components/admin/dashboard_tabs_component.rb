# frozen_string_literal: true

module Admin
  class DashboardTabsComponent < ViewComponent::Base
    def initialize(active_tab: 'overview')
      @active_tab = active_tab
    end

    private

    attr_reader :active_tab

    def tabs
      [
        { id: 'overview', label: 'Aperçu', icon: 'bar-chart-3' },
        { id: 'sessions', label: 'Sessions', icon: 'calendar' },
        { id: 'finances', label: 'Finances', icon: 'euro' },
        { id: 'coaches', label: 'Coachs', icon: 'users' },
        { id: 'alerts', label: 'Alertes', icon: 'alert-triangle' }
      ]
    end

    def tab_classes(tab_id)
      base_classes = "flex items-center px-4 py-2 text-sm font-medium rounded-lg transition-colors"
      
      if active_tab == tab_id
        "#{base_classes} bg-asmbv-red text-white"
      else
        "#{base_classes} text-gray-600 hover:text-gray-900 hover:bg-gray-100"
      end
    end
  end
end
