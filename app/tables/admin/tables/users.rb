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
          col(:name, "Nom", sort: %w[users.last_name users.first_name], csv: ->(user) { "#{user.last_name} #{user.first_name}" }),
          col(:email, "Email", sort: "users.email", filter: DataTable::Filters::Text.new("users.email"), csv: :email.to_proc),
          col(:roles, "Rôles", filter: roles_filter, csv: ->(user) { roles(user).join(", ") }),
          col(:license_type, "Licence", sort: "users.license_type", filter: license_filter, csv: ->(user) { license_label(user) }),
          col(:activated, "Licence payée", sort: "users.activated_at", filter: DataTable::Filters::Boolean.new(scope: method(:activated)),
                                           csv: ->(user) { yes_no(user.activated?) }),
          col(:dossier_complet, "Dossier complet", filter: DataTable::Filters::Boolean.new("users.dossier_complet"),
                                                   csv: ->(user) { yes_no(user.dossier_complet?) }),
          col(:levels, "Groupe", filter: levels_filter(UserLevel, :user_id), class_name: "min-w-56",
                                 csv: ->(user) { user.levels.map(&:display_name).join(", ") }),
          col(:actions, "", class_name: "w-24")
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

      def yes_no(value) = value ? "Oui" : "Non"

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
    end
  end
end
