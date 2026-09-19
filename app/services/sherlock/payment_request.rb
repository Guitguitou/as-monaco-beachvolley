# frozen_string_literal: true

module Sherlock
  # Requête de paiement prête à être postée : l'URL cible et les champs à
  # poster, sans HTML. C'est la vue qui rend le formulaire, pour que la page de
  # redirection soit aux couleurs du club et échappée par Rails.
  PaymentRequest = Data.define(:url, :fields)
end
