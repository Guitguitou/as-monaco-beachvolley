# frozen_string_literal: true

module Admin
  # Coloris d'un article (cf. GLOSSARY.md), avec leur photo.
  class ShopColorsController < ShopProductPartsController
    private

    def part_class = Shop::Color

    def notices = { create: "Coloris ajouté", update: "Coloris mis à jour", destroy: "Coloris supprimé" }

    def anchor = "coloris"

    def permitted = %i[name hex photo position]
  end
end
