# frozen_string_literal: true

module Admin
  # Coupes d'un article (cf. GLOSSARY.md) : prix et tailles.
  class ShopCutsController < ShopProductPartsController
    private

    def part_class = Shop::Cut

    def notices = { create: "Coupe ajoutée", update: "Coupe mise à jour", destroy: "Coupe supprimée" }

    def anchor = "coupes"

    def permitted = %i[label price_eur sizes_text size_guide_id position]
  end
end
