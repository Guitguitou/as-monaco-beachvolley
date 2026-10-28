# frozen_string_literal: true

module Shop
  # Guide des tailles d'une marque (cf. GLOSSARY.md) : une ligne par taille,
  # avec la mesure du corps et un repère facultatif (âge pour les enfants).
  class SizeGuide < ApplicationRecord
    validates :name, :measure_label, :rows, presence: true

    scope :ordered, -> { order(:name) }

    def rows_text = SizeGuideRows.format(rows)

    def rows_text=(text)
      self.rows = SizeGuideRows.parse(text)
    end
  end
end
