# frozen_string_literal: true

module Shop
  # Groupes d'entraînement (niveaux) des joueurs, pour remettre l'équipement
  # par groupe : « Intermédiaire, Loisir » pour un joueur de deux groupes.
  class TrainingGroups
    NONE = "Sans groupe"

    def initialize(user_ids)
      @user_ids = user_ids.uniq
    end

    def of(user_id) = names.fetch(user_id, NONE)

    private

    def names
      @names ||= UserLevel.where(user_id: @user_ids).joins(:level).order("levels.name")
                          .pluck(:user_id, "levels.name")
                          .group_by(&:first).transform_values { |pairs| pairs.map(&:last).join(", ") }
    end
  end
end
