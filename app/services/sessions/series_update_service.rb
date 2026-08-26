module Sessions
  # Propage une modification de session aux sessions SUIVANTES de sa série
  # (édition « cette session et les suivantes », style Gmail).
  #
  # - Les dates sont décalées du même delta que la session éditée
  #   (start_at, end_at, cancellation_deadline_at, registration_opens_at).
  # - Le contenu est recopié depuis la session éditée (titre, terrain, prix/type,
  #   max joueurs, coach, description, notes, groupes + priorités).
  # - Best-effort : les sessions en échec (ex. chevauchement de terrain) sont
  #   listées dans `failures` sans bloquer les autres.
  #
  # La session éditée elle-même est supposée déjà sauvegardée par l'appelant.
  class SeriesUpdateService
    # Attributs de contenu recopiés tels quels depuis la session éditée.
    CONTENT_ATTRIBUTES = %i[
      title description coach_notes session_type terrain max_players user_id
    ].freeze

    def self.call(edited_session:, old_start:, scope:)
      new(edited_session: edited_session, old_start: old_start, scope: scope).call
    end

    def initialize(edited_session:, old_start:, scope:)
      @edited_session = edited_session
      @old_start = old_start
      @scope = scope.to_s
    end

    def call
      return empty_result unless applicable?

      delta = @edited_session.start_at - @old_start
      priorities = level_priorities_hash

      updated_count = 0
      failures = []

      target_sessions.each do |session|
        if apply_to(session, delta, priorities)
          updated_count += 1
        else
          failures << "#{label(session)} : #{session.errors.full_messages.to_sentence}"
        end
      rescue StandardError => e
        failures << "#{label(session)} : #{e.message}"
      end

      { updated_count: updated_count, failures: failures }
    end

    private

    def applicable?
      @scope == "following" &&
        @edited_session.series? &&
        @edited_session.start_at.present? &&
        @old_start.present?
    end

    # Sessions suivantes (strictement après l'ancienne date de la session éditée),
    # self exclu.
    def target_sessions
      @edited_session.series_sessions
                     .where("start_at > ?", @old_start)
                     .where.not(id: @edited_session.id)
                     .order(:start_at)
                     .to_a
    end

    def apply_to(session, delta, priorities)
      shift_dates(session, delta)
      copy_content(session)

      # On sauvegarde d'abord les dates + contenu ; les groupes ne sont réaffectés
      # qu'ensuite pour ne pas muter la table de jointure si la validation échoue.
      return false unless session.save

      session.level_ids = @edited_session.level_ids
      session.sync_level_priorities(priorities) if priorities.present?
      session.rebalance! if session.entrainement?
      true
    end

    def shift_dates(session, delta)
      session.start_at += delta if session.start_at
      session.end_at += delta if session.end_at
      session.cancellation_deadline_at += delta if session.cancellation_deadline_at
      session.registration_opens_at += delta if session.registration_opens_at
    end

    def copy_content(session)
      CONTENT_ATTRIBUTES.each do |attr|
        session.public_send("#{attr}=", @edited_session.public_send(attr))
      end
    end

    def level_priorities_hash
      @edited_session.session_levels.pluck(:level_id, :priority).to_h
    end

    def label(session)
      session.start_at&.strftime("%d/%m/%Y %H:%M") || "Session ##{session.id}"
    end

    def empty_result
      { updated_count: 0, failures: [] }
    end
  end
end
