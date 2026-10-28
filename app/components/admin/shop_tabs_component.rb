# frozen_string_literal: true

module Admin
  # Écran Boutique équipements (cf. GLOSSARY.md) : articles et guides des tailles.
  class ShopTabsComponent < SectionTabsComponent
    TITLE = "Boutique équipements"
    ICON = "shirt"
    TABS = {
      products: { label: "Articles", icon: "shirt", path: :admin_shop_products_path },
      size_guides: { label: "Guides des tailles", icon: "ruler", path: :admin_shop_size_guides_path }
    }.freeze
  end
end
