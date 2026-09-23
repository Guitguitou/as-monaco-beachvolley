module Sessions
  # Filtrage de la liste admin des sessions : coach, période/dates puis type.
  # Expose aussi les compteurs par type (calculés AVANT le filtre de type)
  # pour alimenter les onglets, ainsi que le type actif validé.
  class AdminFilterQuery
    Result = Struct.new(:relation, :type_counts, :current_type, keyword_init: true) do
      def total_count
        type_counts.values.sum
      end

      def filtered_count
        current_type ? type_counts[current_type].to_i : total_count
      end
    end

    def self.call(relation:, params:)
      new(relation: relation, params: params).call
    end

    def initialize(relation:, params:)
      @relation = relation
      @params = params
    end

    def call
      scoped = filter_by_coach(relation)
      scoped = filter_by_date(scoped)

      type_counts = scoped.group(:session_type).count
      current_type = valid_type(params[:session_type])
      scoped = scoped.where(session_type: current_type) if current_type

      Result.new(
        relation: scoped.order(start_at: :desc),
        type_counts: type_counts,
        current_type: current_type
      )
    end

    private

    attr_reader :relation, :params

    def filter_by_coach(scope)
      params[:coach_id].present? ? scope.where(user_id: params[:coach_id]) : scope
    end

    # Une période nommée (week, month, year) prime sur les dates saisies ; une
    # seule borne saisie donne une plage ouverte.
    def filter_by_date(scope)
      return filter_by_period(scope) if params[:period].present?

      from = parse_time(params[:start_at_from])
      to = parse_time(params[:start_at_to])
      from || to ? scope.where(start_at: from..to) : scope
    end

    def filter_by_period(scope)
      range = Reporting::CurrentPeriods.ranges[params[:period].to_sym]
      range ? scope.where(start_at: range) : scope
    end

    def parse_time(value)
      value.presence && Time.zone.parse(value)
    rescue ArgumentError, TypeError
      nil
    end

    def valid_type(type)
      type.presence && Session.session_types.key?(type) ? type : nil
    end
  end
end
