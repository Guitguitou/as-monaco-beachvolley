# frozen_string_literal: true

module Coach
  # Bibliothèque des entraînements annotés par les coachs, rangés par niveau
  # (un entraînement multi-niveaux apparaît sous chacun), les plus récents en
  # premier. Les entraînements ouverts à tous sont rangés sous `nil`.
  class TrainingLibrary
    def initialize(user:, only_mine:)
      @user = user
      @only_mine = only_mine
    end

    def by_level_id
      @by_level_id ||= trainings.each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |training, groups|
        (training.levels.presence || [ nil ]).each { |level| groups[level&.id] << training }
      end
    end

    def levels
      Level.where(id: by_level_id.keys.compact).index_by(&:id)
    end

    private

    def trainings
      scope = Session.includes(:levels).trainings.where.not(coach_notes: [ nil, "" ]).order(start_at: :desc)
      @only_mine ? scope.where(user_id: @user.id) : scope
    end
  end
end
