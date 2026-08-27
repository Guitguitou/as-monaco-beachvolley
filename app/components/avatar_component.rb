# frozen_string_literal: true

# Pastille d'initiales pour un joueur.
#
# Le calcul des initiales était recopié dans sessions/show, sessions/_participants
# et users/_profile_tab, avec trois replis différents quand le nom manque.
class AvatarComponent < ApplicationComponent
  def initialize(user:, size: :md, variant: :solid, ring: false)
    @user = user
    @size = size
    @variant = variant
    @ring = ring
  end

  def initials
    return "?" if user.blank?

    first = user.first_name.to_s.strip
    last = user.last_name.to_s.strip
    return "#{first[0]}#{last[0]}".upcase if first.present? && last.present?

    parts = user.full_name.to_s.split
    return "?" if parts.empty?
    return "#{parts[0][0]}#{parts[1][0]}".upcase if parts.size >= 2

    parts[0][0, 2].to_s.upcase
  end

  private

  attr_reader :user, :size, :variant, :ring

  def classes
    [
      "shrink-0 inline-flex items-center justify-center rounded-full font-bold select-none",
      size_classes,
      variant_classes,
      ring ? "ring-2 ring-white" : nil
    ].compact.join(" ")
  end

  def size_classes
    case size.to_sym
    when :xs then "h-7 w-7 text-[10px]"
    when :sm then "h-9 w-9 text-xs"
    when :lg then "h-14 w-14 text-lg font-anton"
    else "h-10 w-10 text-sm"
    end
  end

  def variant_classes
    case variant.to_sym
    when :light then "bg-asmbv-red/10 text-asmbv-red"
    when :dark then "bg-gray-900 text-white"
    else "bg-asmbv-red text-white"
    end
  end
end
