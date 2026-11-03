# frozen_string_literal: true

module Mcp
  module Tools
    # Crée ou modifie un coloris d'article (cf. GLOSSARY.md), avec sa photo.
    class SaveShopColor < Base
      tool_name "save_shop_color"
      description "Crée ou modifie un coloris d'un article (admins uniquement), avec sa photo affichée quand le membre " \
                  "le choisit. La photo se donne par une URL https publique d'une image (jpeg, png, webp, gif, 10 Mo " \
                  "au plus) : elle remplace la photo actuelle."
      input_schema(
        properties: {
          product_id: { type: "integer" },
          id: ShopWriting::ID,
          name: { type: "string" },
          hex: { type: "string", description: "Couleur au format #RRGGBB." },
          photo_url: { type: "string", format: "uri" },
          position: { type: "integer" }
        },
        required: %w[product_id]
      )
      annotations(**WRITE, open_world_hint: true)

      class << self
        def permission = ShopWriting::PERMISSION

        def execute(_context, product_id:, id: nil, photo_url: nil, **attributes)
          product = Shop::Product.find(product_id)
          color = ShopWriting.find_or_new(Shop::Color.of(product), id)
          color.assign_attributes(product: product, **attributes)
          color.photo.attach(**PhotoDownload.new(photo_url).call.to_h) if photo_url
          { color: ShopWriting.color(save!(color)) }
        end
      end
    end
  end
end
