# frozen_string_literal: true

# Barre de navigation basse, mobile uniquement.
#
# La navigation mobile passait uniquement par un menu hamburger : deux taps et
# un plein écran pour changer d'onglet. Cette app se consulte debout, au bord du
# terrain, à une main — les destinations principales doivent être à un pouce.
class BottomNavComponent < ApplicationComponent
  Item = Struct.new(:label, :path, :icon, :match, keyword_init: true)

  def initialize(user:, current_path:)
    @user = user
    @current_path = current_path
  end

  def render?
    user.present? && items.any?
  end

  private

  attr_reader :user, :current_path

  def items
    @items ||= if user.activated?
      [
        Item.new(label: "Terrain", path: helpers.home_path, icon: "house", match: %w[/mon-terrain]),
        Item.new(label: "Calendrier", path: helpers.sessions_path, icon: "calendar", match: %w[/sessions]),
        Item.new(label: "Annonces", path: helpers.annonces_path, icon: "megaphone", match: %w[/annonces]),
        Item.new(label: "Boutique", path: helpers.packs_path, icon: "credit-card", match: %w[/packs /stages]),
        Item.new(label: "Profil", path: helpers.profile_path, icon: "user", match: %w[/profile])
      ]
    else
      [
        Item.new(label: "Boutique", path: helpers.packs_path, icon: "credit-card", match: %w[/packs]),
        Item.new(label: "Stages", path: helpers.stages_path, icon: "flag", match: %w[/stages]),
        Item.new(label: "Profil", path: helpers.profile_path, icon: "user", match: %w[/profile])
      ]
    end
  end

  # Un onglet reste actif sur les pages filles (/sessions/42 garde Calendrier).
  def active?(item)
    item.match.any? { |prefix| current_path == prefix || current_path.start_with?("#{prefix}/") }
  end

  def item_classes(item)
    base = "flex flex-col items-center justify-center gap-1 flex-1 min-w-0 py-2 " \
           "focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-asmbv-red"
    active?(item) ? "#{base} text-asmbv-red" : "#{base} text-gray-500 hover:text-gray-900"
  end
end
