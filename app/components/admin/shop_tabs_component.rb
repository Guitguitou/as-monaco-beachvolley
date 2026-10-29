# frozen_string_literal: true

module Admin
  # Écran Boutique équipements (cf. GLOSSARY.md) : campagnes, commandes, récap
  # pour les marques, articles et guides des tailles.
  class ShopTabsComponent < SectionTabsComponent
    TITLE = "Boutique équipements"
    ICON = "shirt"
    TABS = {
      campaigns: { label: "Campagnes", icon: "calendar-range", path: :admin_shop_campaigns_path },
      orders: { label: "Commandes", icon: "receipt", path: :admin_shop_orders_path },
      recap: { label: "Récap", icon: "clipboard-list", path: :admin_shop_recap_path },
      products: { label: "Articles", icon: "shirt", path: :admin_shop_products_path },
      size_guides: { label: "Guides des tailles", icon: "ruler", path: :admin_shop_size_guides_path }
    }.freeze
  end
end
