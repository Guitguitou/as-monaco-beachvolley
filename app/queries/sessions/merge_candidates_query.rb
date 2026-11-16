module Sessions
  # Entraînements avec lesquels une séance peut être fusionnée : même créneau,
  # même prix, non annulés (cf. Sessions::MergeEligibility).
  class MergeCandidatesQuery
    def self.call(session:)
      return Session.none unless session.entrainement? && !session.cancelled?

      Session.trainings.held
             .where(start_at: session.start_at, end_at: session.end_at, price: session.price)
             .where.not(id: session.id)
             .includes(:levels, :user)
    end
  end
end
