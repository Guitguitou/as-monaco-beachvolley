# frozen_string_literal: true

class InfosController < ApplicationController
  # Pages d'informations publiques (accessibles connecté ou non)
  # Rassemblent les contenus de l'accueil en sous-pages dédiées
  skip_before_action :authenticate_user!

  def index; end

  def videos; end

  def planning_trainings; end

  def planning_season; end

  def internal_rules; end

  def reservations_leads; end

  def brochure; end

  def registration_rules; end
end
