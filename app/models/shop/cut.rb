# frozen_string_literal: true

module Shop
  # Coupe d'un article (cf. GLOSSARY.md) : son prix et ses tailles.
  class Cut < ApplicationRecord
    SIZE_SEPARATOR = ","

    belongs_to :product
    belongs_to :size_guide, optional: true

    validates :label, presence: true
    validates :price_cents, numericality: { greater_than: 0 }
    validates :sizes, presence: true

    scope :of, ->(product) { where(product_id: product.id).order(:position, :id) }

    def price_eur = price_cents.to_i / 100.0

    def price_eur=(euros)
      self.price_cents = (euros.to_s.tr(",", ".").to_f * 100).round
    end

    def sizes_text = sizes.join("#{SIZE_SEPARATOR} ")

    def sizes_text=(text)
      self.sizes = text.to_s.split(SIZE_SEPARATOR).map(&:strip).compact_blank.uniq
    end
  end
end
