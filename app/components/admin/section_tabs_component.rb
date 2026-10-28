# frozen_string_literal: true

module Admin
  # En-tête d'un écran d'admin à onglets : un seul titre et une barre
  # d'onglets, chaque onglet restant une page d'admin à part entière. Chaque
  # écran déclare TITLE, ICON et TABS.
  class SectionTabsComponent < ApplicationComponent
    renders_one :actions

    def initialize(active:)
      @active = active
    end

    def self.paths(routes) = self::TABS.values.map { |tab| routes.public_send(tab[:path]) }

    private

    def title = self.class::TITLE

    def icon = self.class::ICON

    def tabs
      self.class::TABS.map do |key, tab|
        { label: tab[:label], icon: tab[:icon], href: helpers.public_send(tab[:path]), active: key == @active }
      end
    end
  end
end
