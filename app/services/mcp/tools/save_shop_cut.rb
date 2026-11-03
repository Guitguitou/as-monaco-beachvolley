# frozen_string_literal: true

module Mcp
  module Tools
    # Crée ou modifie une coupe d'article (cf. GLOSSARY.md) : prix et tailles.
    class SaveShopCut < Base
      tool_name "save_shop_cut"
      description "Crée ou modifie une coupe d'un article (admins uniquement) : libellé (Homme, Femme, Enfant…), " \
                  "prix en euros et tailles proposées."
      input_schema(
        properties: {
          product_id: { type: "integer" },
          id: ShopWriting::ID,
          label: { type: "string" },
          price_eur: { type: "number" },
          sizes: { type: "array", items: { type: "string" }, description: "Tailles dans l'ordre d'affichage." },
          size_guide_id: { type: [ "integer", "null" ], description: "Guide des tailles (null pour le détacher)." },
          position: { type: "integer" }
        },
        required: %w[product_id]
      )
      annotations(**WRITE)

      class << self
        def permission = ShopWriting::PERMISSION

        def execute(_context, product_id:, id: nil, **attributes)
          product = Shop::Product.find(product_id)
          cut = ShopWriting.find_or_new(Shop::Cut.of(product), id)
          cut.assign_attributes(product: product, **attributes)
          { cut: ShopWriting.cut(save!(cut)) }
        end
      end
    end
  end
end
