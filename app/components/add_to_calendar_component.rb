# frozen_string_literal: true

# Self-contained "Add to calendar" button. Point it at a .ics endpoint and it renders a
# link that lets the user add the event to Apple Calendar, Google Calendar or Outlook.
#
# Fully exportable: it knows nothing about sessions or any specific model — it only needs
# a URL. Reuse it anywhere by rendering:
#
#   render AddToCalendarComponent.new(url: calendar_session_path(@session, format: :ics))
#
# Options:
#   url:        (required) href of the .ics resource
#   google_url: Google Calendar "add event" URL, utilisé à la place du .ics sur Android
#               (où le fichier serait seulement téléchargé). Voir Calendar::GoogleUrl.
#   label:      button text
#   variant:    :secondary (default), :primary, :ghost
#   size:       :small, :medium (default), :large
#   icon:       lucide icon name (default "calendar-plus")
#   full_width: stretch to container width (default true)
#   filename:   value for the anchor's `download` attribute (optional)
class AddToCalendarComponent < ApplicationComponent
  def initialize(url:, google_url: nil, label: "Ajouter à l'agenda", variant: :secondary, size: :medium,
                 icon: "calendar-plus", full_width: true, filename: nil)
    @url = url
    @google_url = google_url
    @label = label
    @variant = variant
    @size = size
    @icon = icon
    @full_width = full_width
    @filename = filename
  end

  private

  attr_reader :url, :google_url, :label, :variant, :size, :icon, :full_width, :filename

  def data_attributes
    attributes = { turbo: false }
    return attributes if google_url.blank?

    attributes.merge(controller: "add-to-calendar", add_to_calendar_google_url_value: google_url)
  end

  def classes
    [
      "inline-flex items-center justify-center gap-2 font-semibold rounded-none",
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
    when :primary
      "bg-asmbv-red text-white hover:bg-asmbv-red-dark focus:ring-asmbv-red"
    when :ghost
      "bg-transparent border border-transparent text-gray-900 hover:bg-gray-100 focus:ring-gray-400"
    else # :secondary
      "bg-gray-100 border border-gray-200 text-gray-900 hover:bg-gray-200 focus:ring-asmbv-red"
    end
  end
end
