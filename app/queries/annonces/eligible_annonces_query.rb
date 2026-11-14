module Annonces
  # Annonces ouvertes qu'un joueur donné est éligible à voir / rejoindre :
  #   (a) niveau compatible — annonce sans niveau = visible par tous, sinon
  #       le joueur doit partager au moins un niveau avec l'annonce ;
  #   (b) au moins un créneau à venir sans conflit avec l'agenda du joueur.
  # Le créateur ne voit pas sa propre annonce via cette query (elle apparaît
  # dans « mes parties »). Triées par créneau le plus proche.
  class EligibleAnnoncesQuery
    def self.call(user:, relation: Annonce.open)
      new(user: user, relation: relation).call
    end

    def initialize(user:, relation:)
      @user = user
      @relation = relation
      @agenda = PlayerAgenda.new(user: user)
    end

    def call
      level_matched
        .select { |annonce| annonce.upcoming_slots.any? { |slot| agenda.free_for?(slot) } }
        .sort_by { |annonce| annonce.upcoming_slots.first.start_at }
    end

    private

    attr_reader :user, :relation, :agenda

    def level_matched
      base = relation.where.not(user_id: user.id).left_joins(:annonce_levels)
      query = base.where(annonce_levels: { level_id: nil })

      if user_level_ids.any?
        query = query.or(base.where(annonce_levels: { level_id: user_level_ids }))
      end

      query.distinct.includes(:user, slots: { availabilities: :user })
    end

    def user_level_ids
      @user_level_ids ||= user.levels.pluck(:id)
    end
  end
end
