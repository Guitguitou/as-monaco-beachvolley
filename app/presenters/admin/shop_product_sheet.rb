# frozen_string_literal: true

module Admin
  # Fiche d'un article dans l'admin : ses coupes et ses coloris, chacun avec
  # son formulaire, plus un formulaire vierge pour en ajouter.
  class ShopProductSheet
    attr_reader :product

    def initialize(product)
      @product = product
    end

    def cuts = @cuts ||= Shop::Cut.of(product).includes(:size_guide).to_a

    def colors = @colors ||= Shop::Color.of(product).with_attached_photo.to_a

    def new_cut = Shop::Cut.new(product: product, position: next_position(cuts))

    def new_color = Shop::Color.new(product: product, hex: "#1a1a1a", position: next_position(colors))

    def size_guide_options = Shop::SizeGuide.ordered.map { |guide| [ guide.name, guide.id ] }

    private

    def next_position(parts) = (parts.map(&:position).max || 0) + 1
  end
end
