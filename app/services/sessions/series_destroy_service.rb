module Sessions
  # Supprime une session ou une session et les suivantes de sa série, en
  # remboursant les participants confirmés (via CancelSessionService).
  #
  # scope:
  #   "this"      => uniquement la session passée en argument
  #   "following" => la session + les suivantes de la même série (start_at >=)
  class SeriesDestroyService
    VALID_SCOPES = %w[this following].freeze

    def self.call(session:, scope: "this")
      new(session: session, scope: scope).call
    end

    def initialize(session:, scope: "this")
      @session = session
      @scope = VALID_SCOPES.include?(scope.to_s) ? scope.to_s : "this"
    end

    def call
      destroyed_count = 0
      failures = []

      target_sessions.each do |session|
        label = session_label(session)
        Sessions::CancelSessionService.call(session: session)
        destroyed_count += 1
      rescue StandardError => e
        failures << "#{label} : #{e.message}"
      end

      { destroyed_count: destroyed_count, failures: failures }
    end

    private

    def target_sessions
      if @scope == "following" && @session.series?
        # Ordonner du plus tôt au plus tard pour un traitement déterministe.
        @session.following_in_series(including_self: true).order(:start_at).to_a
      else
        [ @session ]
      end
    end

    def session_label(session)
      date = session.start_at&.strftime("%d/%m/%Y %H:%M")
      [ session.title.presence, date ].compact.join(" ")
    end
  end
end
