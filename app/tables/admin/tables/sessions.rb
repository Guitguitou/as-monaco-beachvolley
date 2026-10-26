# frozen_string_literal: true

module Admin
  module Tables
    # Tableau des séances de l'admin.
    class Sessions < DataTable::Definition
      STATUSES = [ [ "Prévue", "held" ], [ "Annulée", "cancelled" ] ].freeze
      LEVELS_SHOWN = 3

      def columns
        [
          DataTable::Column.new(key: :title, label: "Titre", sort: "sessions.title",
                                filter: DataTable::Filters::Text.new("sessions.title")),
          DataTable::Column.new(key: :session_type, label: "Type", sort: "sessions.session_type",
                                filter: DataTable::Filters::Select.new("sessions.session_type", options: type_options)),
          DataTable::Column.new(key: :start_at, label: "Date", sort: "sessions.start_at",
                                filter: DataTable::Filters::DateRange.new("sessions.start_at")),
          DataTable::Column.new(key: :terrain, label: "Terrain",
                                filter: DataTable::Filters::Select.new("sessions.terrain_id", options: terrain_options)),
          DataTable::Column.new(key: :levels, label: "Niveau", filter: levels_filter),
          DataTable::Column.new(key: :coach, label: "Encadrant",
                                filter: DataTable::Filters::Select.new("sessions.user_id", options: coach_options)),
          DataTable::Column.new(key: :participants, label: "Inscrits"),
          DataTable::Column.new(key: :status, label: "Statut", filter: status_filter),
          DataTable::Column.new(key: :actions, label: "", class_name: "w-24")
        ]
      end

      def search_columns = %w[sessions.title sessions.description]

      def quick_filters
        [
          DataTable::QuickFilter.new(key: :upcoming, label: "À venir", scope: ->(sessions) { sessions.held.upcoming }),
          DataTable::QuickFilter.new(key: :this_week, label: "Cette semaine",
                                     scope: ->(sessions) { sessions.where(start_at: Time.current.all_week) }),
          DataTable::QuickFilter.new(key: :cancelled, label: "Annulées", scope: ->(sessions) { sessions.cancelled })
        ]
      end

      def default_order = { start_at: :desc }

      # Les premiers niveaux, puis le nombre de niveaux restants.
      def levels_label(session)
        names = session.levels.map(&:name)
        return "–" if names.empty?

        rest = names.size - LEVELS_SHOWN
        [ names.first(LEVELS_SHOWN).join(", "), ("+#{rest}" if rest.positive?) ].compact.join(" ")
      end

      private

      def type_options = Session.session_types.keys.map { |type| [ ::Sessions::SessionType.for(type).label, type ] }

      def terrain_options = Terrain.ordered.map { |terrain| [ terrain.name, terrain.id ] }

      def coach_options
        User.where(id: Session.select(:user_id)).order(:last_name, :first_name).map { |user| [ user.full_name, user.id ] }
      end

      def levels_filter
        DataTable::Filters::Select.new(
          options: Level.order(:name).map { |level| [ level.display_name, level.id ] }, multiple: true,
          scope: ->(sessions, ids) { sessions.where(id: SessionLevel.where(level_id: ids).select(:session_id)) }
        )
      end

      def status_filter
        DataTable::Filters::Select.new(options: STATUSES, scope: lambda { |sessions, status|
          status == "cancelled" ? sessions.cancelled : sessions.held
        })
      end
    end
  end
end
