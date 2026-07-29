module Licenses
  # Réinitialise les licences pour une nouvelle saison.
  #
  # Pour chaque membre actuellement activé :
  #   - s'il a réglé la licence de la prochaine saison (next_season_renewed) →
  #     on le garde activé et on consomme la coche (remise à false) ;
  #   - sinon → on le désactive (activated_at = nil). Il devra racheter une licence.
  #
  # Idempotent : relancer après coup ne désactive personne de plus.
  class ResetSeason
    Result = Struct.new(:kept, :deactivated, keyword_init: true)

    def self.call
      new.call
    end

    def call
      kept = 0
      deactivated = 0

      ActiveRecord::Base.transaction do
        User.activated.find_each do |user|
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
