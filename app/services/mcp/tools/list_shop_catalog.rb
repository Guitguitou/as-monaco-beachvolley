# frozen_string_literal: true

module Mcp
  module Tools
    # Catalogue de la boutique équipements, comme l'onglet Articles de l'admin :
    # donne les id utiles pour modifier articles, coupes, coloris et guides.
    class ListShopCatalog < Base
      tool_name "list_shop_catalog"
      description "Catalogue de la boutique équipements : campagnes, articles (en vente ou retirés) avec leurs coupes " \
                  "(prix, tailles, guide des tailles) et coloris (photo ou non), et guides des tailles."
      input_schema(properties: {})
      annotations(**READ_ONLY)

      class << self
        def permission = [ :read, :admin_users ]

        def execute(_context)
          {
            campaigns: Shop::Campaign.ordered.map { |campaign| ShopWriting.campaign(campaign) },
            products: Shop::Product.ordered.map { |product| ShopWriting.product(product) },
            size_guides: Shop::SizeGuide.ordered.map { |guide| ShopWriting.size_guide(guide) }
          }
        end
      end
    end
  end
end
