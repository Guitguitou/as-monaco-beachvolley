# frozen_string_literal: true

module Shop
  # Coloris d'un article (cf. GLOSSARY.md), avec sa photo.
  class Color < ApplicationRecord
    belongs_to :product
    has_one_attached :photo

    validates :name, presence: true
    validates :hex, format: { with: /\A#\h{6}\z/ }

    scope :of, ->(product) { where(product_id: product.id).order(:position, :id) }
  end
end
