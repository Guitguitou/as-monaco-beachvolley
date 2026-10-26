# frozen_string_literal: true

module Admin
  module Tables
    # Tableau des séances de l'admin.
    class Sessions < DataTable::Definition
      STATUSES = [ [ "Prévue", "held" ], [ "Annulée", "cancelled" ] ].freeze
      LEVELS_SHOWN = 3

      def columns
        [
          col(:title, "Titre", sort: "sessions.title", filter: DataTable::Filters::Text.new("sessions.title")),
          col(:session_type, "Type", sort: "sessions.session_type", filter: select_filter("sessions.session_type", type_options)),
          date_col(:start_at, "Date", "sessions.start_at"),
          col(:terrain, "Terrain", filter: select_filter("sessions.terrain_id", options_from(Terrain.ordered))),
          col(:levels, "Niveau", filter: levels_filter(SessionLevel, :session_id)),
          col(:coach, "Encadrant", filter: select_filter("sessions.user_id", coach_options)),
          col(:participants, "Inscrits"),
          col(:status, "Statut", filter: status_filter),
          col(:actions, "", class_name: "w-24")
        ]
      end

      def search_columns = %w[sessions.title sessions.description]

      def quick_filters
        [
          DataTable::QuickFilter.new(key: :upcoming, label: "À venir", scope: ->(sessions) { sessions.held.upcoming }),
          current_period(:this_week, "Cette semaine", :start_at, :all_week),
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

      def coach_options = options_from(User.where(id: Session.select(:user_id)).order(:last_name, :first_name), :full_name)

      def status_filter
        DataTable::Filters::Select.new(options: STATUSES, scope: lambda { |sessions, status|
          status == "cancelled" ? sessions.cancelled : sessions.held
        })
      end
    end
  end
end
