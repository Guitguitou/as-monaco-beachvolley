# frozen_string_literal: true

# Barre d'onglets « underline » standard de l'app (liens vers une même page
# qui basculent un paramètre de filtre, avec surlignage de l'onglet actif).
#
#   render TabsComponent.new(tabs: [
#     { label: "Toutes",   href: sessions_path,                   active: true,  count: 42 },
#     { label: "Tournois", href: sessions_path(session_type: :tournoi), active: false, count: 3, icon: "trophy" }
#   ], turbo_frame: "sessions_list")
#
# Chaque onglet est un Hash :
#   label:  (String, requis)  texte affiché
#   href:   (String, requis)  URL déjà construite par l'appelant
#   active: (Boolean)         onglet courant
#   count:  (Integer, option) pastille de comptage — non affichée si nil
#   icon:   (String, option)  nom d'icône lucide
#
# turbo_frame: (String, option) — si présent, les liens ciblent ce Turbo Frame
# et poussent l'URL dans l'historique (turbo_action "advance").
class TabsComponent < ApplicationComponent
  def initialize(tabs:, turbo_frame: nil)
    @tabs = Array(tabs).compact.map(&:symbolize_keys)
    @turbo_frame = turbo_frame
  end

  private

  attr_reader :tabs, :turbo_frame

  def tab_classes(active)
    base = "whitespace-nowrap flex items-center gap-2 px-3 sm:px-4 py-2.5 " \
           "text-sm font-medium border-b-2 -mb-px transition-colors"
    state = if active
      "border-asmbv-red text-asmbv-red"
    else
      "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
    end
    "#{base} #{state}"
  end

  def badge_classes(active)
    base = "ml-1 inline-flex items-center justify-center rounded-full px-1.5 py-0.5 text-xs font-semibold"
    state = active ? "bg-asmbv-red/10 text-asmbv-red" : "bg-gray-100 text-gray-500"
    "#{base} #{state}"
  end

  def link_data
    return {} unless turbo_frame

    { turbo_frame: turbo_frame, turbo_action: "advance" }
  end
end
