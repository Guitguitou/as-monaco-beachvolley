# frozen_string_literal: true

# Self-contained "Partager sur WhatsApp" button. Point it at a pre-filled text
# and it renders a link opening WhatsApp's share sheet (the user picks the
# group/contact). No API, no phone number required.
#
#   render WhatsappShareComponent.new(text: "Jeu libre samedi 10h, Terrain 1 …")
#
# Options mirror AddToCalendarComponent for a consistent look & feel.
class WhatsappShareComponent < ApplicationComponent
  def initialize(text:, label: "Partager sur WhatsApp", variant: :primary, size: :medium,
                 icon: "message-circle", full_width: true)
    @text = text
    @label = label
    @variant = variant
    @size = size
    @icon = icon
    @full_width = full_width
  end

  private

  attr_reader :text, :label, :variant, :size, :icon, :full_width

  def href
    "https://wa.me/?text=#{CGI.escape(text.to_s)}"
  end

  def classes
    [
      "inline-flex items-center justify-center gap-2 font-semibold rounded-lg",
      "focus:outline-none focus:ring-2 focus:ring-offset-2 transition-colors duration-150",
      ("w-full" if full_width),
      size_classes,
      variant_classes
    ].compact.join(" ")
  end

  def size_classes
    case size.to_sym
    when :small then "px-3 py-2 text-sm"
    when :large then "px-5 py-3 text-base"
    else "px-4 py-2 text-sm"
    end
  end

  def variant_classes
    case variant.to_sym
    when :secondary
      "bg-gray-100 border border-gray-200 text-gray-900 hover:bg-gray-200 focus:ring-asmbv-red"
    when :ghost
      "bg-transparent border border-transparent text-gray-900 hover:bg-gray-100 focus:ring-gray-400"
    else # :primary — vert WhatsApp
      "bg-[#25D366] text-white hover:bg-[#1ebe5d] focus:ring-[#25D366]"
    end
  end
end
