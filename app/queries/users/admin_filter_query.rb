# frozen_string_literal: true

module Users
  # Recherche, filtres et tri de la liste des utilisateurs de l'admin.
  class AdminFilterQuery
    SORTS = {
      "name" => [ "last_name ASC, first_name ASC", "last_name DESC, first_name DESC" ],
      "email" => [ "email ASC", "email DESC" ],
      "license_type" => [ "license_type ASC", "license_type DESC" ]
    }.freeze

    def self.call(relation:, params:)
      new(params).apply(relation)
    end

    def initialize(params)
      @params = params
    end

    def apply(relation)
      relation = search(relation) if @params[:q].present?
      relation = relation.joins(:levels).where(levels: { gender: @params[:gender] }).distinct if @params[:gender].present?
      relation = relation.where(license_type: @params[:license_type]) if @params[:license_type].present?
      sort(relation)
    end

    private

    def search(relation)
      query = "%#{@params[:q].strip}%"
      users = User.arel_table
      relation.where(users[:first_name].matches(query).or(users[:last_name].matches(query)).or(users[:email].matches(query)))
    end

    # Sans tri demandé, un ordre stable pour la pagination.
    def sort(relation)
      orders = SORTS[@params[:sort].to_s]
      return relation.order(:last_name, :first_name) unless orders

      relation.order(Arel.sql(orders[@params[:direction] == "desc" ? 1 : 0]))
    end
  end
end
