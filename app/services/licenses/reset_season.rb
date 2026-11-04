module Licenses
  # Réinitialise les licences pour une nouvelle saison.
  #
  # Pour chaque membre dont la licence est payée :
  #   - s'il a réglé la licence de la prochaine saison (next_season_renewed) →
  #     on garde sa licence payée et on consomme la coche (remise à false) ;
  #   - sinon → on efface sa licence (activated_at = nil). Il devra la racheter.
  #
  # Le Dossier complet est décoché pour tous : les pièces valent pour une saison
  # (ADR 0004), même pour ceux qui ont déjà renouvelé.
  #
  # À lancer une seule fois par saison : un second passage effacerait les
  # licences renouvelées (coche déjà consommée) et les dossiers recochés depuis.
  class ResetSeason
    Result = Struct.new(:kept, :deactivated, keyword_init: true)

    def self.call
      new.call
    end

    def call
      kept = 0
      deactivated = 0

      ActiveRecord::Base.transaction do
        User.where(dossier_complet: true).update_all(dossier_complet: false, updated_at: Time.current)
        User.licence_payee.find_each do |user|
          if user.next_season_renewed?
            user.update!(next_season_renewed: false)
            kept += 1
          else
            user.update!(activated_at: nil)
            deactivated += 1
          end
        end
      end

      Result.new(kept: kept, deactivated: deactivated)
    end
  end
end
