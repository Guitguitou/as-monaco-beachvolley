module Registrations
  # Critère A de la priorité d'inscription à un entraînement : 0 si le joueur n'a
  # pas d'autre entraînement confirmé *plus ancien* sur la même semaine ISO,
  # 1 sinon. Binaire, et jamais bloquant : il ne fait que déclasser.
  #
  # « Plus ancien » est essentiel. Sans lui, deux inscriptions du même joueur sur
  # une même semaine se pénalisent mutuellement et il peut être démoté des deux.
  # Avec, exactement une inscription par joueur et par semaine porte le rang 0 :
  # sa première. C'est aussi auto-correctif s'il quitte celle-ci.
  class WeeklyPriorityRule
    PRIORITY = 0
    SECONDARY = 1

    # Clé d'ancienneté d'une inscription. `id` départage les created_at égaux ;
    # une inscription non persistée est considérée comme la plus récente.
    def self.key(created_at, id)
      [ created_at || Time.current, id || Float::INFINITY ]
    end

    # La semaine d'une session est celle de son `start_at` : un entraînement
    # dimanche 22h → lundi 0h30 appartient à la semaine du dimanche.
    def self.week_range(start_at)
      moment = start_at.in_time_zone
      moment.beginning_of_week(:monday)..moment.end_of_week(:monday)
    end

    # Sur la semaine en cours, tout le monde est à égalité.
    def self.neutral_week?(start_at)
      start_at.in_time_zone.to_date.beginning_of_week(:monday) ==
        Time.zone.today.beginning_of_week(:monday)
    end

    def self.rank(earliest_peer_key:, own_key:)
      return PRIORITY if earliest_peer_key.nil?

      (earliest_peer_key <=> own_key) == -1 ? SECONDARY : PRIORITY
    end
  end
end
