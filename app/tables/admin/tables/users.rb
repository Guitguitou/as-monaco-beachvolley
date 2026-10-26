# frozen_string_literal: true

module Admin
  module Tables
    # Tableau des joueurs de l'admin.
    class Users < DataTable::Definition
      ROLES = {
        "admin" => "Admin", "coach" => "Coach", "responsable" => "Responsable", "financial_manager" => "Resp. financier"
      }.freeze
      LICENSES = [ [ "Libre", "libre" ], [ "Compétition", "competition" ], [ "Pas de licence", "none" ] ].freeze

      def columns
        [
          DataTable::Column.new(key: :name, label: "Nom", sort: %w[users.last_name users.first_name],
                                csv: ->(user) { "#{user.last_name} #{user.first_name}" }),
          DataTable::Column.new(key: :email, label: "Email", sort: "users.email",
                                filter: DataTable::Filters::Text.new("users.email"), csv: :email.to_proc),
          DataTable::Column.new(key: :roles, label: "Rôles", filter: roles_filter, csv: ->(user) { roles(user).join(", ") }),
          DataTable::Column.new(key: :license_type, label: "Licence", sort: "users.license_type", filter: license_filter,
                                csv: ->(user) { license_label(user) }),
          DataTable::Column.new(key: :activated, label: "Licence payée", sort: "users.activated_at",
                                filter: DataTable::Filters::Boolean.new(scope: method(:activated)),
                                csv: ->(user) { user.activated? ? "Oui" : "Non" }),
          DataTable::Column.new(key: :dossier_complet, label: "Dossier complet",
                                filter: DataTable::Filters::Boolean.new("users.dossier_complet"),
                                csv: ->(user) { user.dossier_complet? ? "Oui" : "Non" }),
          DataTable::Column.new(key: :levels, label: "Groupe", filter: levels_filter, class_name: "min-w-56",
                                csv: ->(user) { user.levels.map(&:display_name).join(", ") }),
          DataTable::Column.new(key: :actions, label: "", class_name: "w-24")
        ]
      end

      def search_columns = %w[users.first_name users.last_name users.email]

      def quick_filters
        [
          DataTable::QuickFilter.new(key: :cannot_book, label: "Ne peut pas réserver",
                                     scope: ->(users) { users.where.not(id: User.peut_reserver.select(:id)) }),
          DataTable::QuickFilter.new(key: :staff, label: "Staff",
                                     scope: ->(users) { users.where(admin: true).or(users.where(financial_manager: true)) }),
          DataTable::QuickFilter.new(key: :disabled, label: "Désactivés", scope: ->(users) { users.where.not(disabled_at: nil) })
        ]
      end

      def default_order = { last_name: :asc, first_name: :asc }

      def roles(user) = ROLES.select { |attribute, _| user.public_send(:"#{attribute}?") }.values

      def license_label(user)
        return "Pas de licence" if user.license_type.blank?

        user.license_type == "libre" ? "Libre" : "Compétition"
      end

      private

      def activated(users, value) = value ? users.activated : users.not_activated

      def roles_filter
        DataTable::Filters::Select.new(options: ROLES.invert.to_a,
                                       scope: ->(users, role) { ROLES.key?(role) ? users.where(role => true) : users })
      end

      def license_filter
        DataTable::Filters::Select.new(options: LICENSES, scope: lambda { |users, license|
          license == "none" ? users.where(license_type: [ nil, "" ]) : users.where(license_type: license)
        })
      end

      def levels_filter
        DataTable::Filters::Select.new(
          options: Level.order(:name).map { |level| [ level.display_name, level.id ] }, multiple: true,
          scope: ->(users, ids) { users.where(id: UserLevel.where(level_id: ids).select(:user_id)) }
        )
      end
    end
  end
end
