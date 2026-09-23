# frozen_string_literal: true

module Admin
  # Classes Tailwind de la pastille d'icône des cartes de chiffres du dashboard.
  # Écrites en entier pour que Tailwind les détecte.
  module CardColor
    CLASSES = {
      "blue" => "bg-blue-50 text-blue-600",
      "green" => "bg-green-50 text-green-600",
      "purple" => "bg-purple-50 text-purple-600",
      "red" => "bg-red-50 text-red-600",
      "orange" => "bg-orange-50 text-orange-600",
      "yellow" => "bg-yellow-50 text-yellow-600"
    }.freeze

    def self.classes(color)
      CLASSES.fetch(color, "bg-gray-50 text-gray-600")
    end
  end
end
