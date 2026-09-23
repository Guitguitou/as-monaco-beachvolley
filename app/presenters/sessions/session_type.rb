# frozen_string_literal: true

module Sessions
  # Libellé, icône et couleurs d'un type de session, partout où il s'affiche.
  class SessionType < Data.define(:label, :icon, :classes)
    TYPES = {
      "entrainement" => new(label: "Entraînement", icon: "dumbbell", classes: "bg-green-100 text-green-800"),
      "jeu_libre" => new(label: "Jeu libre", icon: "volleyball", classes: "bg-blue-100 text-blue-800"),
      "tournoi" => new(label: "Tournoi", icon: "trophy", classes: "bg-purple-100 text-purple-800"),
      "coaching_prive" => new(label: "Coaching privé", icon: "shield-user", classes: "bg-orange-100 text-orange-800"),
      "stage" => new(label: "Stage", icon: "calendar", classes: "bg-yellow-100 text-yellow-800")
    }.freeze

    def self.for(session_type)
      TYPES.fetch(session_type.to_s) do
        new(label: session_type.to_s.humanize, icon: "volleyball", classes: "bg-gray-100 text-gray-800")
      end
    end
  end
end
