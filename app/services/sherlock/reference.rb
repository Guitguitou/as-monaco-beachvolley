# frozen_string_literal: true

module Sherlock
  # Retrouve NOTRE référence marchande dans une réponse Sherlock's. C'est la
  # seule clé de rapprochement entre nos achats et les réponses de LCL, et elle
  # est lue par les deux entrées : le retour navigateur et le webhook.
  #
  # L'ordre compte. Quand la requête de paiement envoie `orderId`, Sherlock's
  # le renvoie tel quel ET ajoute sa propre `transactionReference` — un
  # horodatage du type "202607021135288e5b", qui ne correspond à aucun de nos
  # achats. Lire `transactionReference` en premier revient donc à chercher la
  # référence de LCL dans notre base, et à ne jamais retrouver l'achat.
  #
  # `orderId` d'abord couvre les deux configurations de contrat : s'il est
  # absent, c'est que la requête envoyait `transactionReference`, et Sherlock's
  # a alors renvoyé la nôtre.
  module Reference
    KEYS = %w[reference orderId transactionReference].freeze

    module_function

    def from(fields)
      normalized = fields.to_h.with_indifferent_access

      KEYS.filter_map { |key| normalized[key].presence }.first
    end
  end
end
