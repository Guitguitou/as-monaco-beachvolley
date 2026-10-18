# frozen_string_literal: true

# Réglages du club modifiables par le Staff (une seule ligne).
# Le lien du formulaire d'adhésion change à chaque saison.
class ClubSetting < ApplicationRecord
  validates :membership_form_url, format: { with: %r{\Ahttps?://\S+\z} }, allow_blank: true

  def self.current
    first_or_create!
  end
end
