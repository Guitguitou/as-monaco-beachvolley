module Annonces
  # Annonces ouvertes qu'un joueur donné est éligible à voir / rejoindre :
  #   (a) niveau compatible — annonce sans niveau = visible par tous, sinon
  #       le joueur doit partager au moins un niveau avec l'annonce ;
  #   (b) au moins un créneau sans conflit avec l'agenda du joueur.
  # Le créateur ne voit pas sa propre annonce via cette query (elle apparaît
  # dans « mes annonces »).
  class EligibleAnnoncesQuery
    def self.call(user:, relation: Annonce.open)
      new(user: user, relation: relation).call
    end

    def initialize(user:, relation:)
      @user = user
      @relation = relation
    end

    def call
      level_matched.select { |annonce| slot_compatible?(annonce) }
    end

    private

    attr_reader :user, :relation

    def level_matched
      base = relation.where.not(user_id: user.id).left_joins(:annonce_levels)
      query = base.where(annonce_levels: { level_id: nil })

      if user_level_ids.any?
        query = query.or(base.where(annonce_levels: { level_id: user_level_ids }))
      end

      query.distinct.includes(slots: :availabilities)
    end

    def user_level_ids
      @user_level_ids ||= user.levels.pluck(:id)
    end

    def slot_compatible?(annonce)
      annonce.slots.any? { |slot| !conflicts?(slot) }
    end

    # Même formule d'overlap que Registrations::ScheduleConflictQuery.
    def conflicts?(slot)
      busy_ranges.any? { |busy_start, busy_end| busy_start < slot.end_at && busy_end > slot.start_at }
    end

    def busy_ranges
      @busy_ranges ||= user.sessions_registered.pluck(:start_at, :end_at)
    end
  end
end
