# frozen_string_literal: true

# Fiche d'un article dans la boutique : ses coupes avec leur guide des tailles
# et ses coloris avec leur photo, dans l'ordre choisi par l'admin.
class ShopProductPage
  attr_reader :product

  def initialize(product)
    @product = product
  end

  def cuts = @cuts ||= Shop::Cut.of(product).includes(:size_guide).to_a

  def colors = @colors ||= Shop::Color.of(product).with_attached_photo.to_a

  def sellable? = cuts.any? && colors.any?

  def several_cuts? = cuts.many?

  def single_size?(cut) = cut.sizes.one?
end
