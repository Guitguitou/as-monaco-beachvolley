# frozen_string_literal: true

# Encadré d'alerte posé dans la page (contrairement à FlashComponent, toast
# éphémère) : erreurs de formulaire, avertissements, confirmations.
#
#   <%= render AlertComponent.new(tone: :error, title: "2 erreurs") do %>
#     <ul>…</ul>
#   <% end %>
class AlertComponent < ApplicationComponent
  TONES = {
    error: { box: "bg-red-50 border-red-200", title: "text-red-800", body: "text-red-700", icon: "alert-circle" },
    warning: { box: "bg-amber-50 border-amber-200", title: "text-amber-800", body: "text-amber-700", icon: "alert-triangle" },
    success: { box: "bg-green-50 border-green-200", title: "text-green-800", body: "text-green-700", icon: "check-circle" },
    info: { box: "bg-blue-50 border-blue-200", title: "text-blue-800", body: "text-blue-700", icon: "info" }
  }.freeze

  def initialize(tone: :info, title: nil, **html_options)
    @tone = TONES.fetch(tone.to_sym)
    @error = tone.to_sym == :error
    @title = title
    @html_options = html_options
  end

  private

  attr_reader :tone, :title

  def wrapper_options
    @html_options.merge(
      role: @error ? "alert" : "status",
      class: [ "flex gap-3 rounded-none border p-4", tone[:box], @html_options[:class] ].compact.join(" ")
    )
  end
end
