# frozen_string_literal: true

# Licence payée mais dossier incomplet : le joueur ne peut pas encore réserver.
# On lui dit quoi faire plutôt que de le laisser écrire au manager.
class DossierPendingComponent < ApplicationComponent
  def initialize(user:)
    @user = user
  end

  def render?
    @user&.dossier_en_attente?
  end

  def form_url
    ClubSetting.current.membership_form_url.presence
  end
end
