module AnnoncesHelper
  # Ex. : « mardi 28 juillet 2026 à 10:00 → 12:00 »
  def annonce_slot_range(slot)
    return "" if slot.start_at.blank? || slot.end_at.blank?

    "#{l(slot.start_at, format: :long)} → #{slot.end_at.strftime('%H:%M')}"
  end

  # Message WhatsApp pré-rempli pour lancer la discussion autour de la session.
  def annonce_whatsapp_text(annonce, session)
    players = session.participants.map(&:full_name).join(", ")
    <<~MSG.strip
      🏐 Jeu libre : #{session.title}
      📅 #{l(session.start_at, format: :long)} → #{session.end_at.strftime('%H:%M')}
      📍 #{session.terrain}
      👥 #{players.presence || 'À confirmer'}

      Rendez-vous : #{annonce_url(annonce)}
    MSG
  end

  # Statut d'une annonce, dans le vocabulaire du joueur.
  # Les badges de statut étaient écrits en dur dans _annonce_card.
  def annonce_status_label(annonce)
    case annonce.status.to_s
    when "open" then annonce.confirmable? ? "Confirmable" : "Ouverte"
    when "confirmed" then "Confirmée"
    when "cancelled" then "Annulée"
    else annonce.status.to_s.humanize
    end
  end

  def annonce_status_variant(annonce)
    case annonce.status.to_s
    when "open" then annonce.confirmable? ? :warning : :info
    when "confirmed" then :success
    when "cancelled" then :neutral
    else :neutral
    end
  end
end
