# frozen_string_literal: true

module Sessions
  # La liste d'attente dans l'ordre RÉEL de promotion :
  # [priorité hebdomadaire, priorité de groupe, ancienneté].
  #
  # Les vues affichaient un simple `order(:created_at)`, qui ignorait déjà la
  # priorité de groupe : un joueur pouvait se croire 4e et passer 1er. Position
  # indicative malgré tout — la promotion saute les joueurs sans crédits.
  class WaitlistOrder
    def self.call(session:)
      new(session: session).call
    end

    def initialize(session:)
      @session = session
    end

    def call
      session.session_levels.load
      registrations = session.registrations.waitlisted.includes(user: :levels).to_a
      weekly = Registrations::WeeklyPriorityResolver.new(session: session).prime(registrations)

      registrations.sort_by do |registration|
        [ weekly.rank_for(registration), registration.priority_rank,
          registration.created_at, registration.id ]
      end
    end

    private

    attr_reader :session
  end
end
