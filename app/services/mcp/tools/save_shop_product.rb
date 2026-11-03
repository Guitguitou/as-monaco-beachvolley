# frozen_string_literal: true

module Mcp
  module Tools
    # Crée ou modifie un article. Un article n'est jamais supprimé : on le
    # retire de la vente (active: false).
    class SaveShopProduct < Base
      tool_name "save_shop_product"
      description "Crée ou modifie un article de la boutique équipements (admins uniquement). " \
                  "Un article ne se supprime pas : active false le retire de la vente. " \
                  "Ses coupes et coloris se gèrent avec save_shop_cut et save_shop_color."
      input_schema(
        properties: {
          id: ShopWriting::ID,
          name: { type: "string" },
          brand: { type: "string" },
          description: { type: "string" },
          marking: { type: "string", description: "Marquage (logo, flocage)." },
          position: { type: "integer", description: "Ordre d'affichage." },
          active: { type: "boolean", description: "En vente." }
        }
      )
      annotations(**WRITE)

      class << self
        def permission = ShopWriting::PERMISSION

        def execute(_context, id: nil, **attributes)
          product = ShopWriting.find_or_new(Shop::Product, id)
          product.assign_attributes(attributes)
          { product: ShopWriting.product(save!(product)) }
        end
      end
    end
  end
end
