module Sessions
  class EligibleForUserLevelsQuery
    def self.call(relation:, level_ids:)
      new(relation: relation, level_ids: level_ids).call
    end

    def initialize(relation:, level_ids:)
      @relation = relation
      @level_ids = Array(level_ids).map(&:to_i).uniq
    end

    def call
      training_type = Session.session_types.fetch("entrainement")
      base_scope = relation.left_joins(:session_levels)
      query = base_scope.where(
        "sessions.session_type != :training_type OR (sessions.session_type = :training_type AND session_levels.level_id IS NULL)",
        training_type: training_type
      )

      if level_ids.any?
        query = query.or(
          base_scope.where(
            "sessions.session_type = :training_type AND session_levels.level_id IN (:level_ids)",
            training_type: training_type,
            level_ids: level_ids
          )
        )
      end

      query.distinct
    end

    private

    attr_reader :relation, :level_ids
  end
end
