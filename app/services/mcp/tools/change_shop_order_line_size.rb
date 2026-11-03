# frozen_string_literal: true

module Mcp
  module Tools
    # Correction de taille sur une ligne de commande payée, aux mêmes
    # conditions que pour le membre (campagne ouverte aux modifications).
    class ChangeShopOrderLineSize < Base
      tool_name "change_shop_order_line_size"
      description "Corrige la taille d'une ligne de commande payée (admins uniquement), dans la même coupe, tant que " \
                  "la campagne accepte les commandes et autorise les modifications."
      input_schema(
        properties: { line_id: { type: "integer", description: "Ligne (cf. list_shop_orders)." }, size: { type: "string" } },
        required: %w[line_id size]
      )
      annotations(**WRITE, idempotent_hint: true)

      class << self
        def permission = ShopWriting::PERMISSION

        def execute(_context, line_id:, size:)
          line = Shop::OrderLine.find(line_id)
          refusal = Shop::ChangeLineSize.new(line:, size:).call
          raise ArgumentError, refusal if refusal

          { line: { id: line.id, order_id: line.order_id, size: line.size } }
        end
      end
    end
  end
end
