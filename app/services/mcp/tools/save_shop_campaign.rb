# frozen_string_literal: true

module Mcp
  module Tools
    # Crée ou modifie une campagne de commande groupée (cf. GLOSSARY.md).
    class SaveShopCampaign < Base
      tool_name "save_shop_campaign"
      description "Crée ou modifie une campagne de commande groupée d'équipements (admins uniquement). " \
                  "Les membres commandent tant qu'elle est ouverte (status open) et que le jour est dans sa période."
      input_schema(
        properties: {
          id: ShopWriting::ID,
          name: { type: "string" },
          opens_on: { type: "string", format: "date" },
          closes_on: { type: "string", format: "date" },
          status: { type: "string", enum: Shop::Campaign.statuses.keys },
          welcome_message: { type: "string", description: "Message affiché en tête de la boutique." },
          allow_edits: { type: "boolean", description: "Les membres peuvent corriger leurs tailles après paiement." }
        }
      )
      annotations(**WRITE)

      class << self
        def permission = ShopWriting::PERMISSION

        def execute(_context, id: nil, **attributes)
          campaign = ShopWriting.find_or_new(Shop::Campaign, id)
          campaign.assign_attributes(attributes)
          { campaign: ShopWriting.campaign(save!(campaign)) }
        end
      end
    end
  end
end
