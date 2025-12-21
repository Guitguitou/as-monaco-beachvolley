# frozen_string_literal: true

# Service pour filtrer et paginer les utilisateurs
# Extrait la logique métier depuis Admin::UsersController#index
class UserFilterService
  PER_PAGE = 25

  def initialize(users, params)
    @users = users
    @params = params
  end

  def call
    apply_search_filter
    apply_gender_filter
    apply_license_type_filter
    apply_sorting
    apply_pagination

    {
      users: @users,
      per_page: PER_PAGE,
      total_count: @total_count,
      total_pages: @total_pages,
      current_page: @current_page
    }
  end

  private

  def apply_search_filter
    return unless @params[:q].present?

    query = "%#{@params[:q].strip}%"
    @users = @users.where(
      User.arel_table[:first_name].matches(query)
        .or(User.arel_table[:last_name].matches(query))
        .or(User.arel_table[:email].matches(query))
    )
  end

  def apply_gender_filter
    return unless @params[:gender].present?

    @users = @users.joins(:levels).where(levels: { gender: @params[:gender] }).distinct
  end

  def apply_license_type_filter
    return unless @params[:license_type].present?

    @users = @users.where(license_type: @params[:license_type])
  end

  def apply_sorting
    allowed_sorts = {
      "name" => [ "last_name ASC, first_name ASC", "last_name DESC, first_name DESC" ],
      "email" => [ "email ASC", "email DESC" ],
      "license_type" => [ "license_type ASC", "license_type DESC" ]
    }

    sort_key = @params[:sort].to_s
    direction = @params[:direction] == "desc" ? 1 : 0

    if allowed_sorts.key?(sort_key)
      @users = @users.order(Arel.sql(allowed_sorts[sort_key][direction]))
    else
      # Default stable ordering for pagination
      @users = @users.order(:last_name, :first_name)
    end
  end

  def apply_pagination
    @total_count = @users.count
    @total_pages = (@total_count.to_f / PER_PAGE).ceil

    requested_page = @params.fetch(:page, 1).to_i
    @current_page = [ requested_page, 1 ].max
    upper_bound = [ @total_pages, 1 ].max
    @current_page = [ @current_page, upper_bound ].min

    offset = (@current_page - 1) * PER_PAGE
    @users = @users.limit(PER_PAGE).offset(offset).includes(:levels)
  end
end
