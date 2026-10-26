# frozen_string_literal: true

module Admin
  # Sections de la barre latérale de l'admin. Le Responsable financier ne voit
  # que Pilotage et Finances (hors Boutique), comme le permettent les gardes
  # des controllers.
  class Navigation
    # `also` : autres chemins pour lesquels le lien est actif.
    Item = Data.define(:label, :path, :icon, :admin_only, :badge, :also) do
      def initialize(label:, path:, icon:, admin_only: true, badge: nil, also: []) = super

      def paths = [ path, *also ].uniq
    end

    # Une section d'un seul lien s'affiche comme ce lien, sans titre repliable.
    Section = Data.define(:title, :icon, :items) do
      def active?(current) = items.any? { |item| current.active?(item) }

      def single? = items.one?
    end

    def initialize(user:, routes:, alerts_count:)
      @user = user
      @routes = routes
      @alerts_count = alerts_count
    end

    def sections
      all_sections.filter_map do |section|
        items = section.items.select { |item| visible?(item) }
        section.with(items: items) if items.any?
      end
    end

    private

    def visible?(item) = @user.admin? || !item.admin_only

    def all_sections
      [ pilotage, activity, members, finances, configuration ]
    end

    def pilotage
      Section.new(title: "Pilotage", icon: "gauge", items: [
        Item.new(label: "Dashboard", path: @routes.admin_root_path, icon: "layout-dashboard", admin_only: false),
        Item.new(label: "Alertes", path: @routes.admin_root_path(tab: "alerts"), icon: "triangle-alert",
                 admin_only: false, badge: @alerts_count.nonzero?)
      ])
    end

    def activity
      Section.new(title: "Activité", icon: "calendar", items: [
        Item.new(label: "Séances", path: @routes.admin_sessions_path, icon: "calendar"),
        Item.new(label: "Stages", path: @routes.admin_stages_path, icon: "flag"),
        Item.new(label: "Tournois", path: @routes.admin_tournaments_path, icon: "trophy"),
        Item.new(label: "Fermetures de terrain", path: @routes.admin_terrain_closures_path, icon: "ban")
      ])
    end

    def members
      Section.new(title: "Membres", icon: "users", items: [
        Item.new(label: "Joueurs", path: @routes.admin_users_path, icon: "users"),
        Item.new(label: "Groupes", path: @routes.admin_groups_path, icon: "users-round"),
        Item.new(label: "Niveaux", path: @routes.admin_levels_path, icon: "layers"),
        Item.new(label: "Saison", path: @routes.admin_season_path, icon: "refresh-cw")
      ])
    end

    def finances
      Section.new(title: "Finances", icon: "euro", items: [
        Item.new(label: "Finances", path: @routes.admin_finances_path, icon: "euro", admin_only: false),
        Item.new(label: "Historique achats", path: @routes.admin_purchase_history_index_path, icon: "shopping-cart",
                 admin_only: false),
        Item.new(label: "Boutique", path: @routes.admin_packs_path, icon: "package")
      ])
    end

    # Un seul écran à onglets (cf. Admin::ConfigurationTabsComponent), actif
    # sur chacun de ses onglets.
    def configuration
      Section.new(title: "Configuration", icon: "settings", items: [
        Item.new(label: "Configuration", path: @routes.admin_club_rules_path, icon: "settings",
                 also: ConfigurationTabsComponent.paths(@routes))
      ])
    end
  end
end
