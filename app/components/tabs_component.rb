# frozen_string_literal: true

class TabsComponent < ViewComponent::Base
  attr_reader :tabs, :active_tab, :interactive

  def initialize(tabs:, active_tab: nil, interactive: true)
    @tabs = tabs
    @active_tab = active_tab
    @interactive = interactive
  end
end

