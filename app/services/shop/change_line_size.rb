# frozen_string_literal: true

module Shop
  # Correction de taille sur une commande payée, tant que la campagne accepte
  # les commandes et autorise les modifications. Le prix ne change pas : la
  # taille reste dans la même coupe.
  class ChangeLineSize
    def initialize(line:, size:)
      @line = line
      @size = size
    end

    # Renvoie le motif du refus, ou nil.
    def call
      error = refusal
      return error if error

      @line.update!(size: @size)
      nil
    end

    private

    def refusal
      campaign = @line.order.campaign
      return "La commande ne peut plus être modifiée." unless @line.order.paid_status? && campaign.allow_edits? && campaign.accepting_orders?

      "Choisis une taille de la liste." unless @line.cut&.sizes&.include?(@size)
    end
  end
end
