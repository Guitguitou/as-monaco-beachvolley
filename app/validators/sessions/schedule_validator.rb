# frozen_string_literal: true

module Sessions
  # Une session doit finir après avoir commencé, sur un terrain ouvert ce
  # jour-là et libre sur tout le créneau. Les champs manquants sont laissés aux
  # validations de présence.
  class ScheduleValidator < ActiveModel::Validator
    OVERLAP_ERRORS = {
      terrain: "est déjà pris sur ce créneau",
      start_at: "chevauche une autre session sur ce terrain",
      end_at: "chevauche une autre session sur ce terrain",
      base: "Une session existe déjà sur ce terrain pendant ces horaires"
    }.freeze

    def validate(session)
      return if session.start_at.blank? || session.end_at.blank? || session.terrain.blank?

      session.errors.add(:end_at, "doit être après la date de début") if session.end_at <= session.start_at
      if TerrainClosure.covers?(terrain: session.terrain, date: session.start_at.to_date)
        session.errors.add(:terrain, "est indisponible à cette date (fermeture ou maintenance)")
      end
      OVERLAP_ERRORS.each { |attribute, message| session.errors.add(attribute, message) } if overlapping?(session)
    end

    private

    def overlapping?(session)
      OverlappingOnTerrainQuery.call(session: session).exists?
    end
  end
end
