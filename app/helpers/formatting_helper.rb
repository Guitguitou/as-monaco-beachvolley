# frozen_string_literal: true

# Formatage des valeurs affichées aux joueurs.
#
# Ces trois formats étaient recalculés à la main dans chaque vue, avec des
# résultats incohérents : « 315 min » pour un tournoi de 5h15, « 0 crédits »
# pour une session gratuite, et « G1, G1 » quand les niveaux homme et femme
# portent le même nom.
module FormattingHelper
  # Durée lisible : 315 → « 5h15 », 120 → « 2h », 45 → « 45 min ».
  def human_duration(minutes)
    minutes = minutes.to_i
    return nil if minutes <= 0
    return "#{minutes} min" if minutes < 60

    hours, remainder = minutes.divmod(60)
    remainder.zero? ? "#{hours}h" : format("%dh%02d", hours, remainder)
  end

  # Durée entre deux horodatages, dans le même format.
  def session_duration(start_at, end_at)
    return nil if start_at.blank? || end_at.blank?

    human_duration(((end_at - start_at) / 60).to_i)
  end

  # Prix en crédits : 0 → « Gratuit », 1 → « 1 crédit », 3 → « 3 crédits ».
  def credits_label(amount)
    amount = amount.to_i
    return "Gratuit" if amount.zero?

    "#{amount} #{amount.abs == 1 ? 'crédit' : 'crédits'}"
  end

  # Niveaux d'une session, dédoublonnés et suffixés par genre (« G1 M », « G1 F »).
  # Renvoie nil quand la session n'impose aucun niveau.
  def session_levels_label(levels)
    labels = Array(levels).map(&:display_name).uniq
    return nil if labels.empty?

    labels.join(", ")
  end

  # Places restantes, formulé côté joueur plutôt qu'en ratio brut.
  # 0 → « Complet », 1 → « 1 place », n → « n places ».
  def spots_left_label(confirmed_count, max_players)
    return nil if max_players.blank?

    left = [ max_players.to_i - confirmed_count.to_i, 0 ].max
    return "Complet" if left.zero?

    "#{left} #{left == 1 ? 'place' : 'places'}"
  end
end
