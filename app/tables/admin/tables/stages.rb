# frozen_string_literal: true

module Admin
  module Tables
    # Stages de l'admin.
    class Stages < DataTable::Definition
      def columns
        [
          DataTable::Column.new(key: :title, label: "Titre", sort: "stages.title"),
          DataTable::Column.new(key: :starts_on, label: "Dates", sort: "stages.starts_on",
                                filter: DataTable::Filters::DateRange.new("stages.starts_on")),
          DataTable::Column.new(key: :coaches, label: "Coachs", filter: coach_filter),
          DataTable::Column.new(key: :actions, label: "", class_name: "w-24")
        ]
      end

      def search_columns = %w[stages.title]

      def quick_filters
        [ DataTable::QuickFilter.new(key: :upcoming, label: "À venir", scope: ->(stages) { stages.where(ends_on: Date.current..) }) ]
      end

      def default_order = { starts_on: :desc }

      private

      def coach_filter
        coaches = User.where(id: Stage.select(:main_coach_id)).or(User.where(id: Stage.select(:assistant_coach_id)))
        DataTable::Filters::Select.new(
          options: coaches.order(:last_name).map { |coach| [ coach.full_name, coach.id ] },
          scope: ->(stages, id) { stages.where(main_coach_id: id).or(stages.where(assistant_coach_id: id)) }
        )
      end
    end
  end
end
