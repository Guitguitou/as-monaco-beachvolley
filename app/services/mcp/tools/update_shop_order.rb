# frozen_string_literal: true

module Mcp
  module Tools
    # Suivi d'une commande, comme l'onglet Commandes de l'admin : remise au
    # membre d'une commande payée, relance d'une commande non finalisée.
    class UpdateShopOrder < Base
      tool_name "update_shop_order"
      description "Suit une commande d'équipements (admins uniquement) : handed_over marque une commande payée comme " \
                  "remise au membre (ou à remettre) ; remind envoie au membre l'e-mail de relance d'une commande " \
                  "non finalisée."
      input_schema(
        properties: {
          id: { type: "integer", description: "Commande (cf. list_shop_orders)." },
          handed_over: { type: "boolean" },
          remind: { type: "boolean" }
        },
        required: %w[id]
      )
      annotations(**WRITE, open_world_hint: true)

      class << self
        def permission = ShopWriting::PERMISSION

        def execute(_context, id:, handed_over: nil, remind: false)
          order = Shop::Order.find(id)
          hand_over(order, handed_over) unless handed_over.nil?
          remind(order) if remind
          { order: { id: order.id, number: order.number, handed_over: order.handed_over?, reminded: remind } }
        end

        private

        def hand_over(order, handed_over)
          raise ArgumentError, "Seule une commande payée se remet au membre." unless order.paid_status?

          order.toggle_handed_over! unless order.handed_over? == handed_over
        end

        def remind(order)
          raise ArgumentError, "La commande est déjà payée : pas de relance." if order.paid_status?

          ShopMailer.unfinished_order(order).deliver_later
        end
      end
    end
  end
end
