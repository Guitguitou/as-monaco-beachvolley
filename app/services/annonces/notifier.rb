module Annonces
  # Notifications push liées au cycle de vie d'une partie de jeu libre :
  #   - à la création : les joueurs éligibles sont prévenus ;
  #   - à chaque nouvelle dispo : le créateur est prévenu ;
  #   - quand un créneau atteint le quota : le créateur est invité à confirmer ;
  #   - quand il ne manque plus qu'un joueur : les joueurs éligibles sont relancés ;
  #   - à la confirmation : les joueurs inscrits reçoivent la session retenue.
  class Notifier
    include Rails.application.routes.url_helpers

    def initialize(annonce:)
      @annonce = annonce
    end

    def notify_eligible_players
      eligible_players.each do |user|
        enqueue(user,
                title: "On cherche des joueurs 🏐",
                body: "#{annonce.user.full_name} veut jouer : #{annonce.title}",
                url: annonce_path(annonce))
      end
    end

    def notify_creator_of_response(from:)
      return if from == annonce.user

      enqueue(annonce.user,
              title: "Un joueur de plus 👍",
              body: "#{from.full_name} en est pour « #{annonce.title} »",
              url: annonce_path(annonce))
    end

    def notify_quota_reached(slot:)
      enqueue(annonce.user,
              title: "Ta partie est prête 🎉",
              body: "#{slot.availabilities.size} joueurs le #{slot_label(slot)}. Confirme-la, sinon elle le sera automatiquement la veille.",
              url: confirm_annonce_path(annonce))
    end

    def notify_last_call(slot:)
      SlotCandidatesQuery.call(slot: slot).find_each do |user|
        enqueue(user,
                title: "Plus qu'un joueur et ça joue 🏐",
                body: "#{annonce.title} — #{slot_label(slot)}",
                url: annonce_path(annonce))
      end
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

    # Joueurs éligibles à au moins un créneau à venir de la partie.
    def eligible_players
      annonce.upcoming_slots.flat_map { |slot| SlotCandidatesQuery.call(slot: slot).to_a }.uniq
    end

    def slot_label(slot)
      "#{I18n.l(slot.start_at.to_date, format: :short_day)} à #{I18n.l(slot.start_at, format: :time)}"
    end

    def enqueue(user, title:, body:, url:)
      SendPushNotificationJob.perform_later(user.id, title: title, body: body, url: url)
    end
  end
end
