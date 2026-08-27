# frozen_string_literal: true

# Écran d'accueil du joueur connecté (« Mon terrain »).
class HomeController < ApplicationController
  # Rails résout le layout par nom de contrôleur : sans cette ligne, `home`
  # capterait `layouts/home.html.erb`, qui est le layout de la page publique
  # (Tailwind CDN, sans navbar) — la page s'affichait sans navigation.
  layout "application"

  before_action :authenticate_user!

  def show
    @dashboard = Home::Dashboard.new(user: current_user)
  end
end
