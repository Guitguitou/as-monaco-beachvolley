# frozen_string_literal: true

module Shop
  # Article de la boutique équipements (cf. GLOSSARY.md). Ses coupes et ses
  # coloris se lisent par Shop::Cut.of / Shop::Color.of. Un article n'est
  # jamais supprimé : on le retire de la vente.
  class Product < ApplicationRecord
    validates :name, :brand, presence: true

    scope :ordered, -> { order(:position, :name) }
    scope :on_sale, -> { where(active: true) }
  end
end
