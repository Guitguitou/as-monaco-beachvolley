# frozen_string_literal: true

module Admin
  # Écran Boutique équipements (cf. GLOSSARY.md) : campagnes, articles et
  # guides des tailles.
  class ShopTabsComponent < SectionTabsComponent
    TITLE = "Boutique équipements"
    ICON = "shirt"
    TABS = {
      campaigns: { label: "Campagnes", icon: "calendar-range", path: :admin_shop_campaigns_path },
      products: { label: "Articles", icon: "shirt", path: :admin_shop_products_path },
      size_guides: { label: "Guides des tailles", icon: "ruler", path: :admin_shop_size_guides_path }
    }.freeze
  end
end
