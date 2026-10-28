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

    def item(label, path, icon, **options) = Item.new(label: label, path: path, icon: icon, **options)

    def section(title, icon, *items) = Section.new(title: title, icon: icon, items: items)

    # [titre, icône, [[libellé, route, icône, options]…]] ; le Responsable
    # financier ne voit que les liens `admin_only: false`.
    SECTIONS = [
      [ "Activité", "calendar", [
        [ "Séances", :admin_sessions_path, "calendar" ], [ "Stages", :admin_stages_path, "flag" ],
        [ "Tournois", :admin_tournaments_path, "trophy" ], [ "Fermetures de terrain", :admin_terrain_closures_path, "ban" ]
      ] ],
      [ "Membres", "users", [
        [ "Joueurs", :admin_users_path, "users" ], [ "Groupes", :admin_groups_path, "users-round" ],
        [ "Niveaux", :admin_levels_path, "layers" ], [ "Saison", :admin_season_path, "refresh-cw" ]
      ] ],
      [ "Finances", "euro", [
        [ "Finances", :admin_finances_path, "euro", { admin_only: false } ],
        [ "Historique achats", :admin_purchase_history_index_path, "shopping-cart", { admin_only: false } ],
        [ "Boutique", :admin_packs_path, "package" ],
        [ "Équipements", :admin_shop_products_path, "shirt", { tabs: ShopTabsComponent } ]
      ] ]
    ].freeze

    def all_sections
      [ pilotage, *SECTIONS.map { |title, icon, items| section(title, icon, *items.map { |entry| routed_item(*entry) }) }, configuration ]
    end

    # `tabs` : écran à onglets (cf. SectionTabsComponent), actif sur chacun d'eux.
    def routed_item(label, route, icon, options = {})
      tabs = options[:tabs]
      item(label, @routes.public_send(route), icon, **options.except(:tabs), also: tabs ? tabs.paths(@routes) : [])
    end

    def pilotage
      section("Pilotage", "gauge",
        item("Dashboard", @routes.admin_root_path, "layout-dashboard", admin_only: false),
        item("Alertes", @routes.admin_root_path(tab: "alerts"), "triangle-alert", admin_only: false, badge: @alerts_count.nonzero?)
      )
    end

    # Un seul écran à onglets (cf. Admin::ConfigurationTabsComponent), actif
    # sur chacun de ses onglets.
    def configuration
      section("Configuration", "settings",
        item("Configuration", @routes.admin_club_rules_path, "settings", also: ConfigurationTabsComponent.paths(@routes))
      )
    end
  end
end
