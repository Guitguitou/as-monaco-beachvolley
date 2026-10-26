# frozen_string_literal: true

module Admin
  module Tables
    # Stages de l'admin.
    class Stages < DataTable::Definition
      def columns
        [
          col(:title, "Titre", sort: "stages.title"),
          date_col(:starts_on, "Dates", "stages.starts_on"),
          col(:coaches, "Coachs", filter: coach_filter),
          col(:actions, "", class_name: "w-24")
        ]
      end

      def search_columns = %w[stages.title]

      def quick_filters = [ upcoming ]

      def default_order = { starts_on: :desc }

      private

      def coach_filter
        coaches = User.where(id: Stage.select(:main_coach_id)).or(User.where(id: Stage.select(:assistant_coach_id)))
        DataTable::Filters::Select.new(
          options: options_from(coaches.order(:last_name), :full_name),
          scope: ->(stages, id) { stages.where(main_coach_id: id).or(stages.where(assistant_coach_id: id)) }
        )
      end
    end
  end
end
