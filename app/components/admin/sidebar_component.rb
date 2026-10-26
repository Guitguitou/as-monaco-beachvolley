# frozen_string_literal: true

module Admin
  # Barre latérale de l'admin : sections repliables (la section de la page
  # courante est ouverte), filtrées selon le rôle.
  class SidebarComponent < ApplicationComponent
    def initialize(navigation:, location:)
      @navigation = navigation
      @location = location
    end

    private

    attr_reader :location

    def sections = @navigation.sections

    def link_classes(item)
      active = location.active?(item)
      [
        "flex items-center gap-3 px-3 py-2 rounded-none hover:bg-gray-100 text-[14px] leading-5",
        active ? "border-l-4 border-brand bg-brand-light text-brand font-semibold" : "text-gray-900 font-medium"
      ].join(" ")
    end

    def icon_classes(item)
      "w-4 h-4 shrink-0 #{location.active?(item) ? 'text-brand' : 'text-gray-500'}"
    end
  end
end
