# frozen_string_literal: true

# Boîte de dialogue native (<dialog>), ouverte par un contrôleur Stimulus.
#
#   <%= render ModalComponent.new(title: "Désinscriptions tardives",
#                                 data: { late_removal_target: "dialog" }) do %>
#     …
#   <% end %>
#
# Les attributs HTML (data-*, id) passent tels quels sur le <dialog> : c'est
# par eux que le contrôleur le retrouve.
class ModalComponent < ApplicationComponent
  renders_one :actions

  def initialize(title:, **html_options)
    @title = title
    @html_options = html_options
  end

  private

  attr_reader :title

  def dialog_options
    @html_options.merge(class: [ "m-auto w-[min(92vw,28rem)] rounded-none p-0 backdrop:bg-black/40",
                                 @html_options[:class] ].compact.join(" "))
  end
end
