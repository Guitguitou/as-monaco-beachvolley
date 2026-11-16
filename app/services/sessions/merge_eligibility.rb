module Sessions
  # Conditions d'une fusion de séances : deux entraînements distincts, non
  # annulés, au même créneau et au même prix.
  class MergeEligibility
    def initialize(kept, absorbed)
      @kept = kept
      @absorbed = absorbed
    end

    def check!
      reason = refusal
      raise MergeService::Error, reason if reason
    end

    def refusal
      sessions = [ @kept, @absorbed ]
      return "Impossible de fusionner une séance avec elle-même." if @kept.id == @absorbed.id
      return "Seuls deux entraînements peuvent être fusionnés." unless sessions.all?(&:entrainement?)
      return "Une séance annulée ne peut pas être fusionnée." if sessions.any?(&:cancelled?)
      return "Les deux séances doivent être sur le même créneau." unless same_slot?
      "Les deux séances doivent avoir le même prix." if @kept.price != @absorbed.price
    end

    private

    def same_slot?
      @kept.start_at == @absorbed.start_at && @kept.end_at == @absorbed.end_at
    end
  end
end
