# frozen_string_literal: true

# Lien « ← Retour » en tête de page.
#
#   render BackLinkComponent.new(href: infos_root_path)
#   render BackLinkComponent.new(href: admin_users_path, label: "Retour aux joueurs")
class BackLinkComponent < ApplicationComponent
  def initialize(href:, label: "Retour")
    @href = href
    @label = label
  end

  def call
    link_to @href, class: "inline-flex items-center gap-1 text-sm text-brand hover:underline" do
      safe_join([ lucide_icon("arrow-left", class: "w-4 h-4", aria: { hidden: true }), @label ])
    end
  end
end
