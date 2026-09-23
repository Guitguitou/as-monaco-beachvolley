# frozen_string_literal: true

# Barre de navigation basse, mobile uniquement.
#
# La navigation mobile passait uniquement par un menu hamburger : deux taps et
# un plein écran pour changer d'onglet. Cette app se consulte debout, au bord du
# terrain, à une main — les destinations principales doivent être à un pouce.
class BottomNavComponent < ApplicationComponent
  Item = Struct.new(:label, :path, :icon, :match, keyword_init: true)

  # [libellé, route, icône, préfixes d'URL qui gardent l'onglet actif]
  MEMBER_ITEMS = [
    [ "Terrain", :home_path, "house", %w[/mon-terrain] ],
    [ "Calendrier", :sessions_path, "calendar", %w[/sessions] ],
    [ "Annonces", :annonces_path, "megaphone", %w[/annonces] ],
    [ "Boutique", :packs_path, "credit-card", %w[/packs /stages] ],
    [ "Profil", :profile_path, "user", %w[/profile] ]
  ].freeze
  # Un compte pas encore activé n'accède qu'à la boutique, aux stages et à son profil.
  GUEST_ITEMS = [
    [ "Boutique", :packs_path, "credit-card", %w[/packs] ],
    [ "Stages", :stages_path, "flag", %w[/stages] ],
    [ "Profil", :profile_path, "user", %w[/profile] ]
  ].freeze

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
    @items ||= (user.activated? ? MEMBER_ITEMS : GUEST_ITEMS).map do |label, route, icon, match|
      Item.new(label: label, path: helpers.public_send(route), icon: icon, match: match)
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
