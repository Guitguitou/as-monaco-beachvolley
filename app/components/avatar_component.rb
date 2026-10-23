# frozen_string_literal: true

# Pastille d'un joueur : sa photo cadrée s'il en a une, ses initiales sinon.
#
# Le calcul des initiales était recopié dans sessions/show, sessions/_participants
# et users/_profile_tab, avec trois replis différents quand le nom manque.
class AvatarComponent < ApplicationComponent
  SIZES = {
    xs: "h-7 w-7 text-[10px]",
    sm: "h-9 w-9 text-xs",
    md: "h-10 w-10 text-sm",
    lg: "h-14 w-14 text-lg font-anton",
    xl: "h-16 w-16 sm:h-20 sm:w-20 text-2xl sm:text-3xl font-anton"
  }.freeze
  VARIANTS = {
    solid: "bg-brand text-white",
    light: "bg-brand/10 text-brand",
    dark: "bg-gray-900 text-white"
  }.freeze

  def initialize(user:, size: :md, variant: :solid, ring: false)
    @user = user
    @size = size
    @variant = variant
    @ring = ring
  end

  # Prénom et nom si les deux sont connus, sinon les mots du nom complet.
  def initials
    words = [ user&.first_name, user&.last_name ].map { |name| name.to_s.strip }
    words = user&.full_name.to_s.split if words.any?(&:blank?)
    return "?" if words.empty?

    (words.size >= 2 ? words[0][0] + words[1][0] : words[0][0, 2]).upcase
  end

  def photo?
    user&.avatar&.attached? && user.avatar.blob.persisted?
  end

  # Même formule que l'éditeur de cadrage (avatar_crop_controller.js) : le point
  # focal reste fixe pendant le zoom, l'aperçu est donc fidèle à toutes tailles.
  def photo_style
    focus = "#{user.avatar_crop_x}% #{user.avatar_crop_y}%"
    "object-position: #{focus}; transform-origin: #{focus}; transform: scale(#{user.avatar_zoom});"
  end

  private

  attr_reader :user, :size, :variant, :ring

  def classes
    [
      "relative shrink-0 inline-flex items-center justify-center overflow-hidden rounded-full font-bold select-none",
      SIZES.fetch(size.to_sym, SIZES[:md]),
      VARIANTS.fetch(variant.to_sym, VARIANTS[:solid]),
      ring ? "ring-2 ring-white" : nil
    ].compact.join(" ")
  end
end
