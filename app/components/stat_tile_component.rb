# frozen_string_literal: true

# Tuile de chiffre clé.
#
# Le même bloc (eyebrow en petites capitales + valeur en Anton tabulaire) était
# recopié dans users/_profile_tab (4 tuiles), coach/trainings/_my_trainings_tab
# (3 cartes de revenus) et home/show (bloc solde). La langue visuelle retenue
# est celle de home/show, la plus récente.
#
#   render StatTileComponent.new(value: 12, label: "Sessions jouées")
#   render StatTileComponent.new(value: 340, label: "Tes crédits", href: packs_path)
#
# `href` transforme la tuile en lien — c'est ce qui permet de rendre le solde
# et les compteurs de sessions cliquables, ce qu'ils n'étaient pas.
class StatTileComponent < ApplicationComponent
  renders_one :action

  def initialize(value:, label:, href: nil, hint: nil, icon: nil, tone: :default, external: false)
    @value = value
    @label = label
    @href = href
    @hint = hint
    @icon = icon
    @tone = tone
    @external = external
  end

  private

  attr_reader :value, :label, :href, :hint, :icon, :tone, :external

  def linked?
    href.present?
  end

  def tag_name
    linked? ? :a : :div
  end

  def tag_options
    opts = { class: classes }
    return opts unless linked?

    opts[:href] = href
    # Les onglets du profil vivent dans un turbo_frame : un lien sortant doit
    # explicitement viser la page entière, sinon Turbo charge la cible dans le
    # frame et la page apparaît tronquée.
    opts[:data] = { turbo_frame: "_top" } if external
    opts
  end

  def classes
    [
      "block border rounded-xl p-5",
      tone_classes,
      linked? ? "transition-colors hover:border-asmbv-red" : nil
    ].compact.join(" ")
  end

  def tone_classes
    case tone.to_sym
    when :accent then "border-transparent bg-gray-900"
    else "border-gray-200 bg-white"
    end
  end

  def label_classes
    base = "text-[11px] font-bold uppercase tracking-widest"
    "#{base} #{tone.to_sym == :accent ? 'text-gray-400' : 'text-gray-500'}"
  end

  def value_classes
    base = "mt-1 font-anton text-3xl leading-none tabular-nums"
    "#{base} #{tone.to_sym == :accent ? 'text-white' : 'text-gray-900'}"
  end

  def hint_classes
    "mt-1 text-xs #{tone.to_sym == :accent ? 'text-gray-400' : 'text-gray-600'}"
  end

  def icon_classes
    "w-5 h-5 shrink-0 #{tone.to_sym == :accent ? 'text-asmbv-red' : 'text-gray-400'}"
  end
end
