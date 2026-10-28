# frozen_string_literal: true

module Shop
  # Articles accompagnés de leurs coupes et coloris, chargés en trois requêtes.
  class Catalog
    Entry = Data.define(:product, :cuts, :colors)

    def initialize(products)
      @products = products.to_a
    end

    def entries
      cuts = parts(Cut.includes(:size_guide))
      colors = parts(Color.with_attached_photo)
      @products.map { |product| Entry.new(product, cuts.fetch(product.id, []), colors.fetch(product.id, [])) }
    end

    private

    def parts(scope)
      scope.where(product_id: @products.map(&:id)).order(:position, :id).group_by(&:product_id)
    end
  end
end
