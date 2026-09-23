# frozen_string_literal: true

module Sessions
  # Édition d'une session par un admin : décale les deadlines non retouchées,
  # enregistre, applique les priorités de groupe, rééquilibre l'entraînement si
  # ses places ou ses groupes ont changé, puis reporte l'édition sur les
  # sessions suivantes de la série si demandé.
  #
  # Le bloc passé à `call` s'exécute juste après l'enregistrement (la synchro
  # des participants, qui dépend de l'utilisateur connecté).
  class AdminUpdate
    Result = Data.define(:saved?, :notice, :failures)

    def initialize(session:, attributes:, level_priorities:, levels_submitted:, scope:)
      @session = session
      @attributes = attributes
      @level_priorities = level_priorities
      @levels_submitted = levels_submitted
      @scope = scope
    end

    def call
      old_start = @session.start_at
      @session.assign_attributes(@attributes)
      DeadlineShift.apply(@session, old_start)
      return Result.new(saved?: false, notice: nil, failures: []) unless @session.save

      places_changed = @session.saved_change_to_max_players?
      @session.sync_level_priorities(@level_priorities)
      yield
      @session.rebalance! if @session.entrainement? && (places_changed || @level_priorities.present? || @levels_submitted)
      follow_series(old_start)
    end

    private

    def follow_series(old_start)
      unless @scope == "following" && @session.has_following_in_series?
        return Result.new(saved?: true, notice: "Session mise à jour avec succès.", failures: [])
      end

      result = SeriesUpdateService.call(edited_session: @session, old_start: old_start, scope: "following")
      Result.new(saved?: true, notice: "Session et #{result[:updated_count]} suivante(s) mises à jour ✅", failures: result[:failures])
    end
  end
end
