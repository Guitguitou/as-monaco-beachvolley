# frozen_string_literal: true

# Service to load training library data grouped by level
class TrainingLibraryService
  def initialize(current_user, only_mine: false)
    @current_user = current_user
    @only_mine = only_mine
  end

  def call
    trainings = load_trainings
    by_level_id = group_by_level(trainings)
    levels = load_levels(by_level_id.keys)

    { by_level_id: by_level_id, levels: levels }
  end

  private

  def load_trainings
    trainings = Session.includes(:levels)
                       .where(session_type: "entrainement")
                       .where.not(coach_notes: [ nil, "" ])
                       .order(start_at: :desc)

    trainings = trainings.where(user_id: @current_user.id) if @only_mine
    trainings
  end

  def group_by_level(trainings)
    by_level_id = Hash.new { |h, k| h[k] = [] }
    trainings.each do |session|
      if session.levels.any?
        session.levels.each { |level| by_level_id[level.id] << session }
      else
        by_level_id[nil] << session
      end
    end
    by_level_id
  end

  def load_levels(level_ids)
    Level.where(id: level_ids.compact).index_by(&:id)
  end
end
