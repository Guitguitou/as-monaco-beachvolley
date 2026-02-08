# frozen_string_literal: true

module Admin
  class PageComponent < ViewComponent::Base
    renders_one :actions
    renders_one :toolbar

    attr_reader :title, :icon

    def initialize(title:, icon: nil)
      @title = title
      @icon = icon
    end
  end
end

