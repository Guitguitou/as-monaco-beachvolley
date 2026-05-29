# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  # ViewComponent 4 no longer mixes in ActionView::Base, so helpers from gems (e.g. lucide-rails)
  # are not available in templates unless accessed via `helpers` or delegated explicitly.
  delegate :lucide_icon, to: :helpers
end
