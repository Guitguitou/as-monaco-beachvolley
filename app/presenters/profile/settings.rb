# frozen_string_literal: true

module Profile
  # Onglet « Réglages » : identité, sécurité, notifications.
  #
  # Le bouton d'activation des notifications push ne vivait que dans la navbar
  # et la sidebar : le profil est l'endroit où un utilisateur va chercher un
  # réglage.
  class Settings
    def initialize(user:)
      @user = user
    end

    def push_devices_count
      @push_devices_count ||= user.push_subscriptions.count
    end

    def push_enabled?
      push_devices_count.positive?
    end

    def role_labels
      user.role_labels
    end

    # Même condition que la navbar pour le lien « Admin ».
    def admin_shortcut?
      user.staff?
    end

    private

    attr_reader :user
  end
end
