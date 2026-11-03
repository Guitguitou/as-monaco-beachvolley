# frozen_string_literal: true

module Mcp
  module Tools
    # Supprime une coupe, un coloris ou un guide des tailles, comme l'admin.
    # Supprimer un guide le détache de ses coupes ; un article ne se supprime pas.
    class DeleteShopItem < Base
      KINDS = { "cut" => Shop::Cut, "color" => Shop::Color, "size_guide" => Shop::SizeGuide }.freeze

      tool_name "delete_shop_item"
      description "Supprime une coupe (cut), un coloris (color) ou un guide des tailles (size_guide) " \
                  "(admins uniquement). Supprimer un guide le détache de ses coupes. Un article ne se supprime pas : " \
                  "save_shop_product avec active false le retire de la vente."
      input_schema(properties: { kind: { type: "string", enum: KINDS.keys }, id: { type: "integer" } }, required: %w[kind id])
      annotations(**WRITE, destructive_hint: true, idempotent_hint: true)

      class << self
        def permission = ShopWriting::PERMISSION

        def execute(_context, kind:, id:)
          model = KINDS[kind] || raise(ArgumentError, "Type inconnu : #{kind} (#{KINDS.keys.join(', ')})")
          model.find(id).destroy!
          { deleted: { kind:, id: } }
        end
      end
    end
  end
end
