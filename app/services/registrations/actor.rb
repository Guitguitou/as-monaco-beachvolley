# frozen_string_literal: true

module Registrations
  # Qui agit sur une inscription, et pour qui : le joueur lui-même, ou un admin
  # / le coach de la session qui inscrit ou retire un autre joueur.
  class Actor
    def initialize(current_user:, session:, params:)
      @current_user = current_user
      @session = session
      @params = params
    end

    # Admins et coach de la session passent outre la date limite d'inscription.
    def privileged?
      @current_user.admin? || @current_user == @session.user
    end

    # Seuls un admin ou le coach de la session agissent pour un autre joueur.
    def acting_for_someone?
      @params[:user_id].present? && privileged?
    end

    def target_user
      acting_for_someone? ? User.find(@params[:user_id]) : @current_user
    end

    def registration
      @session.registrations.find_by(user_id: acting_for_someone? ? @params[:user_id] : @current_user.id)
    end

    # Seul le Staff peut excuser une désinscription tardive (cf. GLOSSARY.md).
    def excused?
      acting_for_someone? && @current_user.staff? && @params[:excused] == "1"
    end

    def deadline_blocks?
      @session.entrainement? && @session.past_registration_deadline? && !privileged?
    end

    # Après la session, seul un admin peut retirer un joueur (remboursement manuel).
    def session_over_for?
      Time.current > @session.end_at && !@current_user.admin?
    end
  end
end
