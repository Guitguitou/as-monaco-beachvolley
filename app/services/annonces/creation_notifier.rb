module Annonces
  # Notifications push liées au cycle de vie d'une annonce :
  #   - à la création : les joueurs éligibles sont prévenus ;
  #   - à chaque nouvelle dispo : le créateur est prévenu ;
  #   - à la confirmation : les joueurs inscrits reçoivent la session retenue.
  class CreationNotifier
    include Rails.application.routes.url_helpers

    def initialize(annonce:)
      @annonce = annonce
    end

    def notify_eligible_players
      eligible_players.each do |user|
        enqueue(user,
                title: "Nouvelle annonce de jeu libre 🏐",
                body: "#{annonce.user.full_name} cherche des joueurs : #{annonce.title}",
                url: annonce_path(annonce))
      end
    end

    def notify_creator_of_response(from:)
      return if from == annonce.user

      enqueue(annonce.user,
              title: "Nouvelle dispo sur ton annonce 👍",
              body: "#{from.full_name} est dispo pour « #{annonce.title} »",
              url: annonce_path(annonce))
    end

    def notify_confirmed(session:, users:)
      users.each do |user|
        enqueue(user,
                title: "Jeu libre confirmé 🎉",
                body: "#{session.display_name} — #{I18n.l(session.start_at, format: :short)}, #{session.terrain}",
                url: session_path(session))
      end
    end

    private

    attr_reader :annonce

    # Joueurs éligibles à cette annonce précise (mêmes critères que l'index).
    def eligible_players
      User.where(id: candidate_ids).select do |user|
        Annonces::EligibleAnnoncesQuery.call(user: user, relation: Annonce.where(id: annonce.id)).any?
      end
    end

    def candidate_ids
      User.activated.where.not(id: annonce.user_id).pluck(:id)
    end

    def enqueue(user, title:, body:, url:)
      SendPushNotificationJob.perform_later(user.id, title: title, body: body, url: url)
    end
  end
end
