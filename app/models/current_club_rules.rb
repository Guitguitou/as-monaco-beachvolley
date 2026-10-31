# frozen_string_literal: true

# Mémoïse les règles du club le temps d'une requête ou d'un job : une seule
# lecture de `club_settings` par unité de travail. Rails remet ces attributs à
# zéro entre deux requêtes / jobs, donc chaque process Puma ou Solid Queue relit
# la valeur à jour sans invalidation inter-process.
class CurrentClubRules < ActiveSupport::CurrentAttributes
  attribute :rules
end
