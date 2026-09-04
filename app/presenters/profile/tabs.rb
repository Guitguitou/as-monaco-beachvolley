# frozen_string_literal: true

module Profile
  # Barre d'onglets de « Mon profil », recoupée par intention.
  #
  # L'ancienne page avait un onglet « Mes sessions » qui dupliquait /me/sessions
  # à l'identique : il est remplacé par un compteur cliquable dans l'onglet
  # « Ma saison ». C'est cette classe qui porte les deux seuls COUNT toujours
  # nécessaires — tout le reste est chargé par le presenter de l'onglet actif.
  class Tabs
    SEASON = "season"
    COACHING = "coaching"
    SETTINGS = "settings"

    def initialize(user:, requested_tab: nil)
      @user = user
      @requested_tab = requested_tab.to_s
    end

    # Onglet courant, toujours l'un des onglets réellement visibles : un
    # `?tab=coaching` forcé par un joueur simple retombe sur « Ma saison ».
    def active
      @active ||= available.include?(requested_tab) ? requested_tab : SEASON
    end

    def season?
      active == SEASON
    end

    def coaching?
      active == COACHING
    end

    def settings?
      active == SETTINGS
    end

    # Coachs et responsables encadrent des sessions ; l'admin voit tout.
    def show_coaching?
      user.coach? || user.responsable? || user.admin?
    end

    def upcoming_count
      @upcoming_count ||= registered_sessions.where("start_at >= ?", Time.current).count
    end

    def past_count
      @past_count ||= registered_sessions.where("end_at < ?", Time.current).count
    end

    def to_a
      [
        { label: "Ma saison", href: path_for(SEASON), active: season?, icon: "id-card" },
        (coaching_tab if show_coaching?),
        { label: "Réglages", href: path_for(SETTINGS), active: settings?, icon: "settings" }
      ].compact
    end

    private

    attr_reader :user, :requested_tab

    def coaching_tab
      { label: "Mon encadrement", href: path_for(COACHING), active: coaching?, icon: "users" }
    end

    def available
      @available ||= [ SEASON, (COACHING if show_coaching?), SETTINGS ].compact
    end

    def path_for(tab)
      Rails.application.routes.url_helpers.profile_path(tab: tab)
    end

    # Pas d'`includes` ici : ces relations ne servent qu'à compter.
    def registered_sessions
      user.sessions_registered
    end
  end
end
