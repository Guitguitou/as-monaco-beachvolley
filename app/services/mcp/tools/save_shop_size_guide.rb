# frozen_string_literal: true

module Mcp
  module Tools
    # Crée ou modifie un guide des tailles (cf. GLOSSARY.md), réutilisé par les coupes.
    class SaveShopSizeGuide < Base
      tool_name "save_shop_size_guide"
      description "Crée ou modifie un guide des tailles (admins uniquement) : une ligne par taille avec la mesure " \
                  "du corps et un repère facultatif (âge pour les enfants). Les lignes fournies remplacent les actuelles."
      input_schema(
        properties: {
          id: ShopWriting::ID,
          name: { type: "string", description: "Souvent la marque et la coupe, ex. « Joma adulte »." },
          measure_label: { type: "string", description: "Mesure du corps, ex. « Tour de poitrine (cm) »." },
          rows: {
            type: "array",
            items: {
              type: "object",
              properties: { size: { type: "string" }, measure: { type: "string" }, note: { type: "string" } },
              required: %w[size]
            }
          }
        }
      )
      annotations(**WRITE)

      class << self
        def permission = ShopWriting::PERMISSION

        def execute(_context, id: nil, rows: nil, **attributes)
          guide = ShopWriting.find_or_new(Shop::SizeGuide, id)
          guide.assign_attributes(attributes)
          guide.rows = rows.map { |row| Shop::SizeGuideRows::KEYS.index_with { |key| row[key.to_sym].to_s.strip } } if rows
          { size_guide: ShopWriting.size_guide(save!(guide)) }
        end
      end
    end
  end
end
